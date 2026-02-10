import Flutter
import UIKit
import Security
import Foundation

public class NativeSecurityKitPlugin: NSObject, FlutterPlugin {
    
    private let kKeyTag = "com.example.native_security_kit.key.v1"
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "native_security_kit", binaryMessenger: registrar.messenger())
        let instance = NativeSecurityKitPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
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
        default:
            result(FlutterMethodNotImplemented)
        }
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
        
        // Try to write to a restricted path
        let stringToWrite = "Jailbreak Test"
        do {
            try stringToWrite.write(toFile: "/private/jailbreak.txt", atomically: true, encoding: .utf8)
            // If writing succeeds, it's jailbroken
            try FileManager.default.removeItem(atPath: "/private/jailbreak.txt")
            return true
        } catch {
            // Expected to fail on non-jailbroken devices
        }
        
        if canOpen(urlScheme: "cydia://") {
            return true
        }
        
        return false
        #endif
    }
    
    private func canOpen(urlScheme: String) -> Bool {
        if let url = URL(string: urlScheme) {
            return UIApplication.shared.canOpenURL(url)
        }
        return false
    }
    
    // MARK: - Simulator Detection
    private func isSimulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - Encryption / Decryption
    
    private func getSecureEnclaveKey() throws -> SecKey {
        // Query for existing key
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
        
        // Create new key if not found
        // Note: kSecAttrTokenIDSecureEnclave is only available on actual devices with Secure Enclave.
        // On simulator, we fall back to standard keychain or handle gracefully.
        // For production grade, we should probably stick to creating a regular key if Secure Enclave is unavailable (e.g. old devices/simulators).
        
        var accessControlError: Unmanaged<CFError>?
        guard let accessControl = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .privateKeyUsage, // Require private key usage permission
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
        
        // Add Secure Enclave flag if available
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
