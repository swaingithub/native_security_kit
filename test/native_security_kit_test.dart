import 'package:flutter_test/flutter_test.dart';
import 'package:native_security_kit/native_security_kit.dart';
import 'package:native_security_kit/native_security_kit_platform_interface.dart';
import 'package:native_security_kit/native_security_kit_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNativeSecurityKitPlatform
    with MockPlatformInterfaceMixin
    implements NativeSecurityKitPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<bool> isDeviceRooted() => Future.value(false);

  @override
  Future<bool> isDeviceJailbroken() => Future.value(false);

  @override
  Future<bool> isRunningOnEmulator() => Future.value(false);

  @override
  Future<String> encrypt(String data) => Future.value('encrypted_$data');

  @override
  Future<String> decrypt(String encrypted) =>
      Future.value(encrypted.replaceFirst('encrypted_', ''));

  @override
  Future<bool> isDebuggerAttached() => Future.value(false);

  @override
  Future<String?> getInstallerSource() => Future.value('com.android.vending');

  @override
  Future<void> toggleScreenSecurity(bool enabled) => Future.value();

  @override
  Future<bool> isUsbDebuggingEnabled() => Future.value(false);

  @override
  Future<bool> isVpnActive() => Future.value(false);

  @override
  Future<bool> isProxyDetected() => Future.value(false);

  @override
  Future<bool> isExternalDisplayConnected() => Future.value(false);

  @override
  Future<String?> getAppSignatureHash() => Future.value('mock_hash');
}

void main() {
  final NativeSecurityKitPlatform initialPlatform = NativeSecurityKitPlatform.instance;

  test('$MethodChannelNativeSecurityKit is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelNativeSecurityKit>());
  });

  test('getPlatformVersion', () async {
    MockNativeSecurityKitPlatform fakePlatform = MockNativeSecurityKitPlatform();
    NativeSecurityKitPlatform.instance = fakePlatform;

    expect(await NativeSecurityKit.getPlatformVersion(), '42');
  });
}
