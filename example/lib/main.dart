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
  // final _nativeSecurityKitPlugin = NativeSecurityKit(); // Removed instance

  String _platformVersion = 'Unknown';
  bool? _isRooted;
  bool? _isEmulator;

  final TextEditingController _textController = TextEditingController();
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

    try {
      platformVersion = await NativeSecurityKit.getPlatformVersion() ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    try {
      isRooted = await NativeSecurityKit.isDeviceRooted();
    } on PlatformException {
      isRooted = false;
    }

    try {
      isEmulator = await NativeSecurityKit.isRunningOnEmulator();
    } on PlatformException {
      isEmulator = false;
    }

    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
      _isRooted = isRooted;
      _isEmulator = isEmulator;
    });
  }

  Future<void> _encrypt() async {
    try {
      final encrypted =
          await NativeSecurityKit.encrypt(_textController.text);
      setState(() {
        _encryptionResult = encrypted;
        _decryptionResult = ''; // Clear previous decryption
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Native Security Kit Example'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Platform: $_platformVersion',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      _StatusRow(
                        label: 'Device Rooted/Jailbroken',
                        isCheck: _isRooted,
                      ),
                      _StatusRow(
                        label: 'Running on Emulator',
                        isCheck: _isEmulator,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Encryption Test',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  labelText: 'Enter text to encrypt',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: _encrypt,
                      child: const Text('Encrypt'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _decrypt,
                      child: const Text('Decrypt Result'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_encryptionResult.isNotEmpty) ...[
                const Text('Encrypted (Base64):'),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SelectableText(
                    _encryptionResult,
                    style: const TextStyle(fontFamily: 'Courier'),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (_decryptionResult.isNotEmpty) ...[
                const Text('Decrypted:'),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Text(
                    _decryptionResult,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final bool? isCheck;

  const _StatusRow({required this.label, required this.isCheck});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          isCheck == true
              ? Icons.warning_amber_rounded
              : Icons.check_circle_outline,
          color: isCheck == true ? Colors.red : Colors.green,
        ),
        const SizedBox(width: 8),
        Text('$label: ${isCheck == null ? "..." : isCheck.toString()}'),
      ],
    );
  }
}
