
import 'native_security_kit_platform_interface.dart';

class NativeSecurityKit {
  static Future<String?> getPlatformVersion() {
    return NativeSecurityKitPlatform.instance.getPlatformVersion();
  }

  /// Checks if the device is rooted (Android) or jailbroken (iOS).
  static Future<bool> isDeviceRooted() {
    return NativeSecurityKitPlatform.instance.isDeviceRooted();
  }

  /// Checks if the device is jailbroken (iOS specific alias).
  static Future<bool> isDeviceJailbroken() {
    return NativeSecurityKitPlatform.instance.isDeviceJailbroken();
  }

  /// Checks if the application is running on an emulator or simulator.
  static Future<bool> isRunningOnEmulator() {
    return NativeSecurityKitPlatform.instance.isRunningOnEmulator();
  }

  /// Encrypts the given string data using a secure, platform-specific method.
  static Future<String> encrypt(String data) {
    return NativeSecurityKitPlatform.instance.encrypt(data);
  }

  /// Decrypts the given encrypted string.
  static Future<String> decrypt(String encrypted) {
    return NativeSecurityKitPlatform.instance.decrypt(encrypted);
  }

  /// Checks if a debugger is attached to the application.
  static Future<bool> isDebuggerAttached() {
    return NativeSecurityKitPlatform.instance.isDebuggerAttached();
  }

  /// Returns the installer source package name (Android) or receipt type (iOS).
  /// Returns null if unknown or side-loaded.
  static Future<String?> getInstallerSource() {
    return NativeSecurityKitPlatform.instance.getInstallerSource();
  }

  /// Enables or disables screen security (prevents screenshots/recording).
  /// Note: Works primarily on Android via FLAG_SECURE. iOS support is limited.
  static Future<void> toggleScreenSecurity(bool enabled) {
    return NativeSecurityKitPlatform.instance.toggleScreenSecurity(enabled);
  }

  /// Checks if USB Debugging (Android) is enabled.
  static Future<bool> isUsbDebuggingEnabled() {
    return NativeSecurityKitPlatform.instance.isUsbDebuggingEnabled();
  }

  /// Checks if a VPN or Proxy is currently active.
  static Future<bool> isVpnActive() {
    return NativeSecurityKitPlatform.instance.isVpnActive();
  }

  /// Checks if an external display (HDMI, AirPlay, etc.) is connected.
  static Future<bool> isExternalDisplayConnected() {
    return NativeSecurityKitPlatform.instance.isExternalDisplayConnected();
  }

  /// Returns the SHA-256 hash of the application signing certificate.
  /// Used to verify that the app has not been re-signed.
  static Future<String?> getAppSignatureHash() {
    return NativeSecurityKitPlatform.instance.getAppSignatureHash();
  }
}
