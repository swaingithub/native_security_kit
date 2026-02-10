package com.example.native_security_kit

import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.nio.charset.StandardCharsets
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/** NativeSecurityKitPlugin */
class NativeSecurityKitPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private val KEY_ALIAS = "NativeSecurityKitKey"
    private val ANDROID_KEY_STORE = "AndroidKeyStore"
    private val TRANSFORMATION = "AES/GCM/NoPadding"

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "native_security_kit")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            "isDeviceRooted" -> {
                result.success(isRooted())
            }
            "isDeviceJailbroken" -> {
                // Jailbreak is an iOS term, but we can treat it as check for root on Android
                // OR return false as it's not applicable. Let's return isRooted() for consistency or false.
                // The prompt asked for "isDeviceJailbroken" implementation on iOS side. For Android side
                // usually we return false or map it to root. I will map it to root for convenience.
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
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    // --- Root Detection ---
    private fun isRooted(): Boolean {
        return checkBuildTags() || checkSuperUserPaths() || checkSuCommand()
    }

    private fun checkBuildTags(): Boolean {
        val buildTags = android.os.Build.TAGS
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
    // --- Emulator Detection ---
    // --- Emulator Detection ---
    private fun isEmulator(): Boolean {
        // 1. Check System Properties (Most reliable for official emulators)
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
            // Ignore reflection errors
        }

        // 2. Check Build fields (Aggregated check for comprehensive coverage)
        val buildInfo = (Build.FINGERPRINT + Build.DEVICE + Build.MODEL + 
                         Build.BRAND + Build.PRODUCT + Build.MANUFACTURER + 
                         Build.HARDWARE + Build.BOARD + Build.BOOTLOADER).lowercase()
        
        return (buildInfo.contains("generic")
                || buildInfo.contains("unknown")
                || buildInfo.contains("emulator")
                || buildInfo.contains("sdk") // Common in emulator products like sdk_gphone...
                || buildInfo.contains("google_sdk")
                || buildInfo.contains("genymotion")
                || buildInfo.contains("goldfish")
                || buildInfo.contains("ranchu")
                || buildInfo.contains("vbox")
                || buildInfo.contains("android_x86") // Specific to x86 emulators
                )
    }

    // --- Encryption / Decryption ---
    private fun encryptData(data: String): String {
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, getSecretKey())
        
        val iv = cipher.iv
        val encryption = cipher.doFinal(data.toByteArray(StandardCharsets.UTF_8))
        
        // Combine IV and encrypted data
        val combined = ByteArray(iv.size + encryption.size)
        System.arraycopy(iv, 0, combined, 0, iv.size)
        System.arraycopy(encryption, 0, combined, iv.size, encryption.size)
        
        return Base64.encodeToString(combined, Base64.DEFAULT)
    }

    private fun decryptData(encryptedData: String): String {
        val decoded = Base64.decode(encryptedData, Base64.DEFAULT)
        
        // Extract IV (GCM standard IV length is usually 12 bytes, but Cipher.getIV() might vary based on provider. 
        // For AES/GCM/NoPadding, 12 bytes is recommended. Android KeyStore usually uses 12 bytes for GCM.
        // However, we should be careful. We can assume 12 bytes for GCM IV or store length.
        // Let's assume 12 bytes as it is standard for GCMParameterSpec.
        // Actually, let's verify IV size. AES block size is 16, but GCM IV is typically 12.
        // Let's rely on the fact we are using the same provider.
        
        val ivSize = 12 // GCM standard
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
