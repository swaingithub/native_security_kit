
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
}
