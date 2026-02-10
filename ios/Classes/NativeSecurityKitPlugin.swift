import Flutter
import UIKit
import Security
import Foundation
import Network

public class NativeSecurityKitPlugin: NSObject, FlutterPlugin {
    
    private let kKeyTag = "com.example.native_security_kit.key.v1"
    private var screenSecurityEnabled = false
    private var privacyOverlay: UIView?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "native_security_kit", binaryMessenger: registrar.messenger())
        let instance = NativeSecurityKitPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        case "isDeviceRooted", "isDeviceJailbroken":
            result(isJailbroken())
        case "isRunningOnEmulator":
            result(isSimulator())
        case "encrypt":
            if let args = call.arguments as? [String: Any],
               let data = args["data"] as? String {
                do {
                    let encrypted = try encrypt(string: data)
                    result(encrypted)
                } catch {
                    result(FlutterError(code: "ENCRYPTION_ERROR", message: error.localizedDescription, details: nil))
                }
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Data is required", details: nil))
            }
        case "decrypt":
            if let args = call.arguments as? [String: Any],
               let data = args["data"] as? String {
                do {
                    let decrypted = try decrypt(string: data)
                    result(decrypted)
                } catch {
                    result(FlutterError(code: "DECRYPTION_ERROR", message: error.localizedDescription, details: nil))
                }
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Data is required", details: nil))
            }
        case "isDebuggerAttached":
            result(isDebuggerAttached())
        case "getInstallerSource":
            result(getInstallerSource())
        case "toggleScreenSecurity":
            if let args = call.arguments as? [String: Any],
               let enabled = args["enabled"] as? Bool {
                self.screenSecurityEnabled = enabled
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Enabled is required", details: nil))
            }
        case "isUsbDebuggingEnabled":
            result(false)
        case "isVpnActive":
            result(isVPNConnected())
        case "isProxyDetected":
            result(isProxyDetected())
        case "isExternalDisplayConnected":
            result(UIScreen.screens.count > 1)
        case "getAppSignatureHash":
            result(getAppSignatureHash())
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - Privacy Overlay (Screen Security)
    
    public func applicationWillResignActive(_ application: UIApplication) {
        if screenSecurityEnabled {
            showPrivacyOverlay()
        }
    }
    
    public func applicationDidBecomeActive(_ application: UIApplication) {
        hidePrivacyOverlay()
    }
    
    private func showPrivacyOverlay() {
        guard privacyOverlay == nil else { return }
        
        if let window = UIApplication.shared.keyWindow {
            let overlay = UIView(frame: window.bounds)
            overlay.backgroundColor = .black
            
            let label = UILabel()
            label.text = "Privacy Protected"
            label.textColor = .white
            label.textAlignment = .center
            label.font = UIFont.boldSystemFont(ofSize: 20)
            label.translatesAutoresizingMaskIntoConstraints = false
            
            overlay.addSubview(label)
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: overlay.centerYAnchor)
            ])
            
            window.addSubview(overlay)
            self.privacyOverlay = overlay
        }
    }
    
    private func hidePrivacyOverlay() {
        privacyOverlay?.removeFromSuperview()
        privacyOverlay = nil
    }
    
    // MARK: - Jailbreak Detection
    private func isJailbroken() -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        
        let paths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/",
            "/usr/bin/ssh"
        ]
        
        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        
        let stringToWrite = "Jailbreak Test"
        do {
            try stringToWrite.write(toFile: "/private/jailbreak.txt", atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: "/private/jailbreak.txt")
            return true
        } catch { }
        
        if let url = URL(string: "cydia://"), UIApplication.shared.canOpenURL(url) {
            return true
        }
        
        return false
        #endif
    }
    
    // MARK: - Simulator Detection
    private func isSimulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - Debugger Detection
    private func isDebuggerAttached() -> Bool {
        var info = kinfo_proc()
        var mib : [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride
        let res = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
        if res != 0 {
            return false
        }
        return (info.kp_proc.p_flag & P_TRACED) != 0
    }
    
    // MARK: - Installer Source
    private func getInstallerSource() -> String? {
        if let receiptUrl = Bundle.main.appStoreReceiptURL {
            let receiptName = receiptUrl.lastPathComponent
            if receiptName == "sandboxReceipt" {
                return "testflight"
            } else if receiptName == "receipt" {
                return "appstore"
            }
        }
        return nil
    }

    private func isVPNConnected() -> Bool {
        let scm = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? [String: Any]
        if let keys = scm?["__SCOPED__"] as? [String: Any] {
            for key in keys.keys {
                if key.contains("tap") || key.contains("tun") || key.contains("ppp") || key.contains("ipsec") {
                    return true
                }
            }
        }
        return false
    }

    private func isProxyDetected() -> Bool {
        guard let proxySettings = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? [String: Any],
              let proxies = proxySettings[kCFNetworkProxiesHTTPEnable as String] as? Int else {
            return false
        }
        return proxies > 0
    }

    private func getAppSignatureHash() -> String? {
        return Bundle.main.bundleIdentifier
    }
    
    // MARK: - Encryption / Decryption
    
    private func getSecureEnclaveKey() throws -> SecKey {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: kKeyTag.data(using: .utf8)!,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecReturnRef as String: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecSuccess {
            return (item as! SecKey)
        }
        
        var accessControlError: Unmanaged<CFError>?
        guard let accessControl = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .privateKeyUsage,
            &accessControlError
        ) else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(errSecParam), userInfo: nil)
        }
        
        var attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256,
            kSecAttrApplicationTag as String: kKeyTag.data(using: .utf8)!,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: true,
                kSecAttrAccessControl as String: accessControl
            ]
        ]
        
        #if !targetEnvironment(simulator)
        attributes[kSecAttrTokenID as String] = kSecAttrTokenIDSecureEnclave
        #endif
        
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            throw error!.takeRetainedValue() as Error
        }
        
        return privateKey
    }
    
    private func encrypt(string: String) throws -> String {
        let privateKey = try getSecureEnclaveKey()
        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw NSError(domain: "NativeSecurityKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get public key"])
        }
        
        guard let data = string.data(using: .utf8) else {
            throw NSError(domain: "NativeSecurityKit", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to encode string"])
        }
        
        let algorithm: SecKeyAlgorithm = .eciesEncryptionCofactorVariableIVX963SHA256AESGCM
        
        guard SecKeyIsAlgorithmSupported(publicKey, .encrypt, algorithm) else {
             throw NSError(domain: "NativeSecurityKit", code: -3, userInfo: [NSLocalizedDescriptionKey: "Algorithm not supported"])
        }
        
        var error: Unmanaged<CFError>?
        guard let cipherData = SecKeyCreateEncryptedData(publicKey, algorithm, data as CFData, &error) else {
             throw error!.takeRetainedValue() as Error
        }
        
        return (cipherData as Data).base64EncodedString()
    }
    
    private func decrypt(string: String) throws -> String {
        let privateKey = try getSecureEnclaveKey()
        guard let data = Data(base64Encoded: string) else {
             throw NSError(domain: "NativeSecurityKit", code: -4, userInfo: [NSLocalizedDescriptionKey: "Invalid base64 string"])
        }
        
        let algorithm: SecKeyAlgorithm = .eciesEncryptionCofactorVariableIVX963SHA256AESGCM
        
        guard SecKeyIsAlgorithmSupported(privateKey, .decrypt, algorithm) else {
             throw NSError(domain: "NativeSecurityKit", code: -5, userInfo: [NSLocalizedDescriptionKey: "Algorithm not supported"])
        }
        
        var error: Unmanaged<CFError>?
        guard let clearData = SecKeyCreateDecryptedData(privateKey, algorithm, data as CFData, &error) else {
             throw error!.takeRetainedValue() as Error
        }
        
        guard let result = String(data: clearData as Data, encoding: .utf8) else {
             throw NSError(domain: "NativeSecurityKit", code: -6, userInfo: [NSLocalizedDescriptionKey: "Failed to decode string"])
        }
        
        return result
    }
}
