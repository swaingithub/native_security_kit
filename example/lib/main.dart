import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:native_security_kit/native_security_kit.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<ScaffoldMessengerState> _messengerKey = GlobalKey<ScaffoldMessengerState>();

  String _platformVersion = 'Unknown';
  bool? _isRooted;
  bool? _isEmulator;
  bool? _isDebuggerAttached;
  bool? _isUsbDebuggingEnabled;
  bool? _isVpnActive;
  bool? _isExternalDisplayConnected;
  String? _installerSource;
  String? _signatureHash;
  bool _screenSecurityEnabled = false;

  final TextEditingController _textController = TextEditingController();
  final TextEditingController _hashController = TextEditingController();
  String _encryptionResult = '';
  String _decryptionResult = '';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    String platformVersion;
    bool isRooted = false;
    bool isEmulator = false;
    bool isDebuggerAttached = false;
    bool isUsbDebuggingEnabled = false;
    bool isVpnActive = false;
    bool isExternalDisplayConnected = false;
    String? installerSource;
    String? signatureHash;

    try {
      platformVersion = await NativeSecurityKit.getPlatformVersion() ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    try {
      isRooted = await NativeSecurityKit.isDeviceRooted();
      isEmulator = await NativeSecurityKit.isRunningOnEmulator();
      isDebuggerAttached = await NativeSecurityKit.isDebuggerAttached();
      isUsbDebuggingEnabled = await NativeSecurityKit.isUsbDebuggingEnabled();
      isVpnActive = await NativeSecurityKit.isVpnActive();
      isExternalDisplayConnected = await NativeSecurityKit.isExternalDisplayConnected();
      installerSource = await NativeSecurityKit.getInstallerSource();
      signatureHash = await NativeSecurityKit.getAppSignatureHash();
    } on PlatformException catch (e) {
      debugPrint("Security check error: ${e.message}");
    }

    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
      _isRooted = isRooted;
      _isEmulator = isEmulator;
      _isDebuggerAttached = isDebuggerAttached;
      _isUsbDebuggingEnabled = isUsbDebuggingEnabled;
      _isVpnActive = isVpnActive;
      _isExternalDisplayConnected = isExternalDisplayConnected;
      _installerSource = installerSource;
      _signatureHash = signatureHash;
    });
  }

  Future<void> _encrypt() async {
    try {
      final encrypted =
          await NativeSecurityKit.encrypt(_textController.text);
      setState(() {
        _encryptionResult = encrypted;
        _decryptionResult = '';
      });
    } on PlatformException catch (e) {
      setState(() {
        _encryptionResult = 'Error: ${e.message}';
      });
    }
  }

  Future<void> _decrypt() async {
    if (_encryptionResult.isEmpty || _encryptionResult.startsWith('Error')) {
      return;
    }
    try {
      final decrypted =
          await NativeSecurityKit.decrypt(_encryptionResult);
      setState(() {
        _decryptionResult = decrypted;
      });
    } on PlatformException catch (e) {
      setState(() {
        _decryptionResult = 'Error: ${e.message}';
      });
    }
  }

  Future<void> _toggleScreenSecurity(bool value) async {
    try {
      await NativeSecurityKit.toggleScreenSecurity(value);
      setState(() {
        _screenSecurityEnabled = value;
      });
      _messengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Screen Security ${value ? 'Enabled' : 'Disabled'}')),
      );
    } on PlatformException catch (e) {
      _messengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Failed: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _messengerKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.light),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Native Security Suite'),
          centerTitle: true,
          elevation: 2,
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: initPlatformState),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 16),
              _buildSecurityDashboard(),
              const SizedBox(height: 16),
              _buildTamperProtectionCard(),
              const SizedBox(height: 16),
              _buildScreenSecurityCard(),
              const SizedBox(height: 16),
              _buildEncryptionCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 0,
      color: Colors.teal.withAlpha(25),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.verified_user_outlined, size: 48, color: Colors.teal),
            const SizedBox(height: 8),
            Text(
              'Security Health Check',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.teal, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('Version: $_platformVersion'),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityDashboard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Environment Monitoring', style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            _StatusRow(label: 'Rooted / Jailbroken', isCheck: _isRooted, warningIfTrue: true),
            _StatusRow(label: 'Emulator', isCheck: _isEmulator, warningIfTrue: true),
            _StatusRow(label: 'Debugger Attached', isCheck: _isDebuggerAttached, warningIfTrue: true),
            _StatusRow(label: 'USB Debugging (ADB)', isCheck: _isUsbDebuggingEnabled, warningIfTrue: true),
            _StatusRow(label: 'VPN / Proxy Active', isCheck: _isVpnActive),
            _StatusRow(label: 'External Display', isCheck: _isExternalDisplayConnected, warningIfTrue: true),
            const Divider(),
            _buildInfoRow(Icons.install_mobile, 'Installer', _installerSource ?? 'Sideloaded/Unknown'),
          ],
        ),
      ),
    );
  }

  Widget _buildTamperProtectionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tamper Protection', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text('App Signature (SHA-256):', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text(_signatureHash ?? 'Checking...', style: const TextStyle(fontFamily: 'Courier', fontSize: 10)),
            const SizedBox(height: 12),
            TextField(
              controller: _hashController,
              decoration: const InputDecoration(
                labelText: 'Verify Release Hash',
                hintText: 'Paste expected base64 hash',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () {
                bool match = _signatureHash?.trim() == _hashController.text.trim();
                _messengerKey.currentState?.showSnackBar(
                  SnackBar(
                    backgroundColor: match ? Colors.green : Colors.red,
                    content: Text(match ? 'Signature Verified!' : 'TAMPER DETECTED: Hash mismatch!'),
                  ),
                );
              },
              child: const Text('Verify Integrity'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenSecurityCard() {
    return Card(
      child: SwitchListTile(
        secondary: const Icon(Icons.no_photography_outlined),
        title: const Text('Screen Privacy Mode'),
        subtitle: const Text('Block screenshots & background snapshots'),
        value: _screenSecurityEnabled,
        onChanged: _toggleScreenSecurity,
      ),
    );
  }

  Widget _buildEncryptionCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Hardware-Backed Vault', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Secret Message',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _encrypt,
                    icon: const Icon(Icons.enhanced_encryption),
                    label: const Text('Seal'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _decrypt,
                    icon: const Icon(Icons.no_encryption),
                    label: const Text('Unseal'),
                  ),
                ),
              ],
            ),
            if (_encryptionResult.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Sealed Data:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              SelectableText(_encryptionResult, style: const TextStyle(fontFamily: 'Courier', fontSize: 10)),
            ],
            if (_decryptionResult.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Unsealed Message:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Text(_decryptionResult, style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final bool? isCheck;
  final bool warningIfTrue;

  const _StatusRow({required this.label, required this.isCheck, this.warningIfTrue = false});

  @override
  Widget build(BuildContext context) {
    bool isAlert = warningIfTrue ? (isCheck == true) : (isCheck == false);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            isCheck == null ? Icons.hourglass_empty : (isAlert ? Icons.warning_amber : Icons.check_circle_outline),
            color: isCheck == null ? Colors.grey : (isAlert ? Colors.orange : Colors.green),
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
          const Spacer(),
          Text(
            isCheck == null ? '...' : (isCheck! ? 'ACTIVE' : 'NONE'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isCheck == null ? Colors.grey : (isAlert ? Colors.red : Colors.green),
            ),
          ),
        ],
      ),
    );
  }
}
