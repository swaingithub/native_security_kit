# Native Security Suite 🛡️

An enterprise-grade security toolkit for Flutter applications. Protect your app from reverse engineering, tampering, and untrusted environments using 100% native security APIs.

## Features

### 🛡️ Device Integrity
* **Root/Jailbreak Detection**: Detects compromised environments using multiple heuristics.
* **Emulator/Simulator Check**: Prevents running in sandboxed or virtualized environments.

### 🔐 Hardware-Backed Encryption
* **Android**: AES-GCM encryption using **Android Keystore**. Keys never leave the TEE (Trusted Execution Environment).
* **iOS**: Hybrid ECIES encryption (NIST P-256) using **Secure Enclave**. Hardware-level protection for sensitive data.

### 🕵️ Runtime & Tamper Protection
* **Debugger Detection**: Detects attached LLDB (iOS) or ADB/JDWP (Android) debuggers.
* **Integrity Check**: Retrieve the app's signing certificate hash (SHA-256) to verify authenticity.
* **USB Debugging**: Detects if ADB is enabled (high-risk).

### 📺 Privacy & Anti-Leakage
* **Screenshot Prevention (Android)**: Blocks system-level screenshots and recordings via `FLAG_SECURE`.
* **Privacy Overlay (iOS)**: Automatically covers app content in the App Switcher and background.
* **External Display**: Detects HDMI/AirPlay mirroring to prevent data leakage.

### 🌐 Network Security
* **VPN/Proxy Detection**: Identifies if the user is masking their network identity.

---

## Installation

Add path to your `pubspec.yaml`:

```yaml
dependencies:
  native_security_kit: ^1.0.0
```

## Usage

### Device Security
```dart
bool isRooted = await NativeSecurityKit.isDeviceRooted();
bool isEmulator = await NativeSecurityKit.isRunningOnEmulator();
bool isDebugger = await NativeSecurityKit.isDebuggerAttached();
```

### Encryption
```dart
// Encrypt data using hardware-backed keys
String encrypted = await NativeSecurityKit.encrypt("secret message");

// Decrypt data
String decrypted = await NativeSecurityKit.decrypt(encrypted);
```

### Privacy Mode
```dart
// Block screenshots and screen recordings
await NativeSecurityKit.toggleScreenSecurity(true);
```

### Integrity Verification
```dart
String? hash = await NativeSecurityKit.getAppSignatureHash();
if (hash != "YOUR_RELEASE_HASH") {
  // Take action (crash, lockout, report)
}
```

## Platform Support
* **Android**: API Level 23+ (Marshmallow)
* **iOS**: ios 12.0+

---

## Security Note
While this plugin provides robust layered security, no single check is 100% foolproof. For maximum protection, use these checks in combination with server-side attestation (SafetyNet/Play Integrity/DeviceCheck).
