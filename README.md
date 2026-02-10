# Native Security Suite

**Enterprise-Grade Native Security Toolkit for Flutter**

A production-ready Flutter plugin providing **deep native security controls** using platform-level APIs. Protect your application from **reverse engineering, tampering, runtime attacks, rooted or jailbroken devices, and untrusted execution environments** using **hardware-backed security mechanisms**.

Designed for **fintech, healthcare, enterprise, government, and high-risk mobile applications**.

---

## Overview

Flutter applications are sandboxed and do not expose many low-level operating system security features. This plugin bridges that gap by exposing **native Android and iOS security APIs** through a clean, consistent, and easy-to-use Dart interface.

It enables:

* Hardware-backed encryption
* Runtime integrity verification
* Device trust evaluation
* Secure screen protection
* Network environment analysis

All with minimal Flutter-side integration.

---

## Key Features

### Device Integrity & Environment Validation

* Root detection (Android)
* Jailbreak detection (iOS)
* Emulator and simulator detection
* Hooking and instrumentation detection (basic heuristics)
* Debugger attachment detection

---

### Hardware-Backed Encryption

* **Android**: AES-GCM encryption via **Android Keystore (TEE-backed)**
* **iOS**: Secure Enclave encryption using **ECIES (NIST P-256)**

All cryptographic keys are generated and stored inside secure hardware and never leave the protected boundary.

---

### Runtime & Tamper Protection

* Debugger detection (ADB / JDWP / LLDB)
* Application signature verification (SHA-256)
* USB debugging detection
* Runtime instrumentation detection

---

### Privacy & Data Leakage Prevention

* Screenshot and screen recording prevention (Android)
* Secure overlay protection in app switcher (iOS)
* External display and screen mirroring detection (HDMI / AirPlay)

---

### Network Security

* VPN detection
* Proxy detection (mapped to VPN/Environment checks)
* Suspicious network routing environment identification

---

## Platform Support

| Platform | Minimum Version |
| -------- | --------------- |
| Android  | API 23+ (6.0)   |
| iOS      | 12.0+           |

---

## Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  native_security_kit: ^1.0.0
```

Then run:

```bash
flutter pub get
```

---

## Usage

### Import

```dart
import 'package:native_security_kit/native_security_kit.dart';
```

---

### Device Integrity Checks

```dart
bool isRooted = await NativeSecurityKit.isDeviceRooted();
bool isJailbroken = await NativeSecurityKit.isDeviceJailbroken();
bool isEmulator = await NativeSecurityKit.isRunningOnEmulator();
bool isDebuggerAttached = await NativeSecurityKit.isDebuggerAttached();
```

---

### Hardware-Backed Encryption

```dart
String encrypted = await NativeSecurityKit.encrypt("Highly Confidential Data");
String decrypted = await NativeSecurityKit.decrypt(encrypted);
```

---

### Screen Protection

```dart
await NativeSecurityKit.toggleScreenSecurity(true);
```

Prevents screenshots and screen recording at the operating system level.

---

### Application Integrity Verification

```dart
String? signatureHash = await NativeSecurityKit.getAppSignatureHash();

if (signatureHash != "YOUR_RELEASE_SIGNATURE_HASH") {
  // Lock application, terminate session, or trigger alert
}
```

---

### Network Risk Detection

```dart
bool vpnActive = await NativeSecurityKit.isVpnActive();
bool proxyDetected = await NativeSecurityKit.isProxyDetected();
```

---

## Architecture Overview

```
Flutter Application
        ↓
NativeSecurityKit (Dart API)
        ↓
Platform Interface
        ↓
Method Channels
        ↓
Android (Kotlin)   → Keystore, System APIs
iOS (Swift)        → Secure Enclave, System APIs
```

This architecture ensures:

* Clean separation of concerns
* Maximum native performance
* Strong security boundaries
* Platform-specific implementation isolation

---

## Recommended Use Cases

* Banking and fintech applications
* Healthcare systems
* Enterprise internal tools
* Government applications
* Crypto wallets
* DRM-protected media apps
* Secure authentication platforms

---

## Security Disclaimer

No client-side protection is fully foolproof.

For production-grade security, always combine device-level protections with:

* Server-side validation
* Play Integrity API / SafetyNet (Android)
* Apple DeviceCheck / App Attest (iOS)
* Backend-based risk scoring and monitoring

Layered security architecture is strongly recommended.

---

## Roadmap

* Google Play Integrity API integration
* Apple App Attest integration
* Advanced runtime hooking detection
* Anti-repackaging verification
* Secure memory APIs

---

## License

MIT License © 2026
Designed for secure Flutter application development.
