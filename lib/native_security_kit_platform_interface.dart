import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'native_security_kit_method_channel.dart';

abstract class NativeSecurityKitPlatform extends PlatformInterface {
  /// Constructs a NativeSecurityKitPlatform.
  NativeSecurityKitPlatform() : super(token: _token);

  static final Object _token = Object();

  static NativeSecurityKitPlatform _instance = MethodChannelNativeSecurityKit();

  /// The default instance of [NativeSecurityKitPlatform] to use.
  ///
  /// Defaults to [MethodChannelNativeSecurityKit].
  static NativeSecurityKitPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NativeSecurityKitPlatform] when
  /// they register themselves.
  static set instance(NativeSecurityKitPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<bool> isDeviceRooted() {
    throw UnimplementedError('isDeviceRooted() has not been implemented.');
  }

  Future<bool> isDeviceJailbroken() {
    throw UnimplementedError('isDeviceJailbroken() has not been implemented.');
  }

  Future<bool> isRunningOnEmulator() {
    throw UnimplementedError('isRunningOnEmulator() has not been implemented.');
  }

  Future<String> encrypt(String data) {
    throw UnimplementedError('encrypt() has not been implemented.');
  }

  Future<String> decrypt(String encrypted) {
    throw UnimplementedError('decrypt() has not been implemented.');
  }

  Future<bool> isDebuggerAttached() {
    throw UnimplementedError('isDebuggerAttached() has not been implemented.');
  }

  Future<String?> getInstallerSource() {
    throw UnimplementedError('getInstallerSource() has not been implemented.');
  }

  Future<void> toggleScreenSecurity(bool enabled) {
    throw UnimplementedError('toggleScreenSecurity() has not been implemented.');
  }

  Future<bool> isUsbDebuggingEnabled() {
    throw UnimplementedError('isUsbDebuggingEnabled() has not been implemented.');
  }

  Future<bool> isVpnActive() {
    throw UnimplementedError('isVpnActive() has not been implemented.');
  }

  Future<bool> isExternalDisplayConnected() {
    throw UnimplementedError('isExternalDisplayConnected() has not been implemented.');
  }

  Future<String?> getAppSignatureHash() {
    throw UnimplementedError('getAppSignatureHash() has not been implemented.');
  }
}
