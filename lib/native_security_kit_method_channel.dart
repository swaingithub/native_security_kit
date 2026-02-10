import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'native_security_kit_platform_interface.dart';

/// An implementation of [NativeSecurityKitPlatform] that uses method channels.
class MethodChannelNativeSecurityKit extends NativeSecurityKitPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('native_security_kit');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<bool> isDeviceRooted() async {
    final rooted = await methodChannel.invokeMethod<bool>('isDeviceRooted');
    return rooted ?? false;
  }

  @override
  Future<bool> isDeviceJailbroken() async {
    final jailbroken =
        await methodChannel.invokeMethod<bool>('isDeviceJailbroken');
    return jailbroken ?? false;
  }

  @override
  Future<bool> isRunningOnEmulator() async {
    final isEmulator =
        await methodChannel.invokeMethod<bool>('isRunningOnEmulator');
    return isEmulator ?? false;
  }

  @override
  Future<String> encrypt(String data) async {
    final encrypted = await methodChannel
        .invokeMethod<String>('encrypt', {'data': data});
    if (encrypted == null) {
      throw PlatformException(
        code: 'ENCRYPTION_FAILED',
        message: 'Encryption returned null',
      );
    }
    return encrypted;
  }

  @override
  Future<String> decrypt(String encrypted) async {
    final decrypted = await methodChannel
        .invokeMethod<String>('decrypt', {'data': encrypted});
    if (decrypted == null) {
      throw PlatformException(
        code: 'DECRYPTION_FAILED',
        message: 'Decryption returned null',
      );
    }
    return decrypted;
  }
}
