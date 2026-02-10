package com.example.native_security_kit

import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.hardware.display.DisplayManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Build
import android.os.Debug
import android.provider.Settings
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import android.view.Display
import android.view.WindowManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.nio.charset.StandardCharsets
import java.security.KeyStore
import java.security.MessageDigest
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/** NativeSecurityKitPlugin */
class NativeSecurityKitPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding? = null
    
    private val KEY_ALIAS = "NativeSecurityKitKey"
    private val ANDROID_KEY_STORE = "AndroidKeyStore"
    private val TRANSFORMATION = "AES/GCM/NoPadding"

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        flutterPluginBinding = binding
        channel = MethodChannel(binding.binaryMessenger, "native_security_kit")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        flutterPluginBinding = null
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${Build.VERSION.RELEASE}")
            }
            "isDeviceRooted" -> {
                result.success(isRooted())
            }
            "isDeviceJailbroken" -> {
                result.success(isRooted())
            }
            "isRunningOnEmulator" -> {
                result.success(isEmulator())
            }
            "encrypt" -> {
                val data = call.argument<String>("data")
                if (data == null) {
                    result.error("INVALID_ARGUMENT", "Data cannot be null", null)
                    return
                }
                try {
                    val encrypted = encryptData(data)
                    result.success(encrypted)
                } catch (e: Exception) {
                    result.error("ENCRYPTION_ERROR", e.message, null)
                }
            }
            "decrypt" -> {
                val data = call.argument<String>("data")
                if (data == null) {
                    result.error("INVALID_ARGUMENT", "Data cannot be null", null)
                    return
                }
                try {
                    val decrypted = decryptData(data)
                    result.success(decrypted)
                } catch (e: Exception) {
                    result.error("DECRYPTION_ERROR", e.message, null)
                }
            }
            "isDebuggerAttached" -> {
                result.success(Debug.isDebuggerConnected() || Debug.waitingForDebugger())
            }
            "getInstallerSource" -> {
                result.success(getInstallerPackageName())
            }
            "toggleScreenSecurity" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                toggleScreenSecurity(enabled)
                result.success(null)
            }
            "isUsbDebuggingEnabled" -> {
                result.success(isUsbDebuggingEnabled())
            }
            "isVpnActive" -> {
                result.success(isVpnActive())
            }
            "isProxyDetected" -> {
                result.success(isProxyDetected())
            }
            "isExternalDisplayConnected" -> {
                result.success(isExternalDisplayConnected())
            }
            "getAppSignatureHash" -> {
                result.success(getAppSignatureHash())
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun getInstallerPackageName(): String? {
        val context = flutterPluginBinding?.applicationContext ?: return null
        return try {
            if (Build.VERSION.SDK_INT >= 30) {
                context.packageManager.getInstallSourceInfo(context.packageName).installingPackageName
            } else {
                @Suppress("DEPRECATION")
                context.packageManager.getInstallerPackageName(context.packageName)
            }
        } catch (e: Exception) {
            null
        }
    }

    private fun toggleScreenSecurity(enabled: Boolean) {
        activity?.let {
            it.runOnUiThread {
                if (enabled) {
                    it.window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                } else {
                    it.window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                }
            }
        }
    }

    private fun isUsbDebuggingEnabled(): Boolean {
        val context = flutterPluginBinding?.applicationContext ?: return false
        return Settings.Global.getInt(context.contentResolver, Settings.Global.ADB_ENABLED, 0) != 0
    }

    private fun isVpnActive(): Boolean {
        val context = flutterPluginBinding?.applicationContext ?: return false
        val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val network = connectivityManager.activeNetwork ?: return false
            val capabilities = connectivityManager.getNetworkCapabilities(network) ?: return false
            return capabilities.hasTransport(NetworkCapabilities.TRANSPORT_VPN)
        } else {
            @Suppress("DEPRECATION")
            val networks = connectivityManager.allNetworks
            for (network in networks) {
                val capabilities = connectivityManager.getNetworkCapabilities(network)
                if (capabilities != null && capabilities.hasTransport(NetworkCapabilities.TRANSPORT_VPN)) {
                    return true
                }
            }
            return false
        }
    }

    private fun isProxyDetected(): Boolean {
        return try {
            val proxyAddress = System.getProperty("http.proxyHost")
            proxyAddress != null && proxyAddress.isNotEmpty()
        } catch (e: Exception) {
            false
        }
    }

    private fun isExternalDisplayConnected(): Boolean {
        val context = flutterPluginBinding?.applicationContext ?: return false
        val displayManager = context.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
        val displays = displayManager.getDisplays()
        for (display in displays) {
            if (display.displayId != Display.DEFAULT_DISPLAY) {
                return true
            }
        }
        return false
    }

    private fun getAppSignatureHash(): String? {
        val context = flutterPluginBinding?.applicationContext ?: return null
        return try {
            val packageInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                context.packageManager.getPackageInfo(context.packageName, PackageManager.GET_SIGNING_CERTIFICATES)
            } else {
                @Suppress("DEPRECATION")
                context.packageManager.getPackageInfo(context.packageName, PackageManager.GET_SIGNATURES)
            }

            val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                packageInfo.signingInfo?.apkContentsSigners
            } else {
                @Suppress("DEPRECATION")
                packageInfo.signatures
            }

            if (signatures != null && signatures.isNotEmpty()) {
                val md = MessageDigest.getInstance("SHA-256")
                md.update(signatures[0].toByteArray())
                val digest = md.digest()
                return Base64.encodeToString(digest, Base64.NO_WRAP)
            }
            null
        } catch (e: Exception) {
            null
        }
    }

    // --- Root Detection ---
    private fun isRooted(): Boolean {
        return checkBuildTags() || checkSuperUserPaths() || checkSuCommand()
    }

    private fun checkBuildTags(): Boolean {
        val buildTags = Build.TAGS
        return buildTags != null && buildTags.contains("test-keys")
    }

    private fun checkSuperUserPaths(): Boolean {
        val paths = arrayOf(
            "/system/app/Superuser.apk",
            "/sbin/su",
            "/system/bin/su",
            "/system/xbin/su",
            "/data/local/xbin/su",
            "/data/local/bin/su",
            "/system/sd/xbin/su",
            "/system/bin/failsafe/su",
            "/data/local/su",
            "/su/bin/su"
        )
        for (path in paths) {
            if (File(path).exists()) return true
        }
        return false
    }

    private fun checkSuCommand(): Boolean {
        return try {
            val process = Runtime.getRuntime().exec(arrayOf("/system/xbin/which", "su"))
            val inStream = java.io.BufferedReader(java.io.InputStreamReader(process.inputStream))
            val line = inStream.readLine()
            process.destroy()
            line != null
        } catch (e: Exception) {
            false
        }
    }

    // --- Emulator Detection ---
    private fun isEmulator(): Boolean {
        try {
            val systemProperties = Class.forName("android.os.SystemProperties")
            val get = systemProperties.getMethod("get", String::class.java)
            val qemu = get.invoke(systemProperties, "ro.kernel.qemu") as String
            if (qemu == "1") return true
            
            val qemu2 = get.invoke(systemProperties, "ro.boot.qemu") as String
            if (qemu2 == "1") return true

            val hardware = get.invoke(systemProperties, "ro.hardware") as String
            if (hardware.contains("goldfish") || hardware.contains("ranchu")) return true
        } catch (e: Exception) {
        }

        val buildInfo = (Build.FINGERPRINT + Build.DEVICE + Build.MODEL + 
                         Build.BRAND + Build.PRODUCT + Build.MANUFACTURER + 
                         Build.HARDWARE + Build.BOARD + Build.BOOTLOADER).lowercase()
        
        return (buildInfo.contains("generic")
                || buildInfo.contains("unknown")
                || buildInfo.contains("emulator")
                || buildInfo.contains("sdk")
                || buildInfo.contains("google_sdk")
                || buildInfo.contains("genymotion")
                || buildInfo.contains("goldfish")
                || buildInfo.contains("ranchu")
                || buildInfo.contains("vbox")
                || buildInfo.contains("android_x86")
                )
    }

    // --- Encryption / Decryption ---
    private fun encryptData(data: String): String {
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, getSecretKey())
        
        val iv = cipher.iv
        val encryption = cipher.doFinal(data.toByteArray(StandardCharsets.UTF_8))
        
        val combined = ByteArray(iv.size + encryption.size)
        System.arraycopy(iv, 0, combined, 0, iv.size)
        System.arraycopy(encryption, 0, combined, iv.size, encryption.size)
        
        return Base64.encodeToString(combined, Base64.DEFAULT)
    }

    private fun decryptData(encryptedData: String): String {
        val decoded = Base64.decode(encryptedData, Base64.DEFAULT)
        val ivSize = 12
        if (decoded.size < ivSize) throw IllegalArgumentException("Invalid data length")
        
        val iv = ByteArray(ivSize)
        System.arraycopy(decoded, 0, iv, 0, ivSize)
        
        val encryptedContent = ByteArray(decoded.size - ivSize)
        System.arraycopy(decoded, ivSize, encryptedContent, 0, encryptedContent.size)
        
        val cipher = Cipher.getInstance(TRANSFORMATION)
        val spec = GCMParameterSpec(128, iv)
        cipher.init(Cipher.DECRYPT_MODE, getSecretKey(), spec)
        
        val original = cipher.doFinal(encryptedContent)
        return String(original, StandardCharsets.UTF_8)
    }

    private fun getSecretKey(): SecretKey {
        val keyStore = KeyStore.getInstance(ANDROID_KEY_STORE)
        keyStore.load(null)
        
        if (!keyStore.containsAlias(KEY_ALIAS)) {
            val keyGenerator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, ANDROID_KEY_STORE)
            val keyGenParameterSpec = KeyGenParameterSpec.Builder(
                KEY_ALIAS,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
            )
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .build()
            
            keyGenerator.init(keyGenParameterSpec)
            return keyGenerator.generateKey()
        }
        
        return keyStore.getKey(KEY_ALIAS, null) as SecretKey
    }
}
