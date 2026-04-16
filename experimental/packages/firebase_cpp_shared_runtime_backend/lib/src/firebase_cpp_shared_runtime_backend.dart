import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:firebase_backend_contract/firebase_backend_contract.dart';

class FirebaseCppSharedRuntimeBackend implements FirebaseExperimentalBackend {
  FirebaseCppSharedRuntimeBackend({
    required this.binaryPath,
  });

  final String binaryPath;

  FirebaseBackendConfig? _config;
  Process? _process;
  StreamQueue<String>? _stdoutLines;

  @override
  Future<void> initialize(FirebaseBackendConfig config) async {
    _config = config;
    await _ensureProcess();
    await _sendSimpleCommand(
      'INIT',
      <String>[config.buildSignInUrl()],
    );
  }

  @override
  Future<FirebaseUserSession> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final List<String> result = await _sendSimpleCommand(
      'SIGN_IN',
      <String>[email, password],
    );
    final int statusCode = int.parse(result[0]);
    final Map<String, Object?> payload =
        jsonDecode(result[1]) as Map<String, Object?>;
    if (statusCode < 200 || statusCode >= 300) {
      throw FirebaseBackendException(
        'Sign-in failed with HTTP $statusCode',
        details: payload,
      );
    }
    return FirebaseUserSession.fromJson(payload);
  }

  @override
  Future<Object?> callFunction(
    String name, {
    Object? data,
    String region = 'us-central1',
  }) async {
    final FirebaseBackendConfig config = _requireConfig();
    final List<String> result = await _sendSimpleCommand(
      'CALLABLE',
      <String>[
        config.buildCallableUrl(name, region: region),
        jsonEncode(<String, Object?>{'data': data}),
      ],
    );
    final int statusCode = int.parse(result[0]);
    final Map<String, Object?> payload =
        jsonDecode(result[1]) as Map<String, Object?>;
    if (payload['error'] case final Map<String, Object?> error) {
      throw FirebaseBackendException(
        (error['message'] ?? 'Callable request failed.') as String,
        details: error['details'],
      );
    }
    if (statusCode < 200 || statusCode >= 300) {
      throw FirebaseBackendException(
        'Callable failed with HTTP $statusCode',
        details: payload,
      );
    }
    return payload['result'] ?? payload['data'] ?? payload['response'];
  }

  @override
  Future<void> dispose() async {
    final Process? process = _process;
    if (process == null) {
      return;
    }

    process.stdin.writeln('DISPOSE');
    await process.stdin.flush();
    await process.stdin.close();
    await process.exitCode.timeout(
      const Duration(seconds: 2),
      onTimeout: () {
        process.kill(ProcessSignal.sigkill);
        return 0;
      },
    );
    _stdoutLines = null;
    _process = null;
  }

  Future<void> _ensureProcess() async {
    if (_process != null) {
      return;
    }

    final Process process = await Process.start(binaryPath, <String>[]);
    _process = process;
    _stdoutLines = StreamQueue<String>(
      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter()),
    );
  }

  Future<List<String>> _sendSimpleCommand(
    String command,
    List<String> values,
  ) async {
    await _ensureProcess();
    final Process process = _process!;
    final StreamQueue<String> stdoutLines = _stdoutLines!;
    final String encodedCommand = <String>[
      command,
      ...values.map((String value) => base64Encode(utf8.encode(value))),
    ].join('\t');
    process.stdin.writeln(encodedCommand);
    await process.stdin.flush();
    final String line = await stdoutLines.next;
    final List<String> parts = line.split('\t');
    if (parts.isEmpty) {
      throw FirebaseBackendException('Runtime host returned an empty response.');
    }
    if (parts.first == 'ERR') {
      throw FirebaseBackendException(
        utf8.decode(base64Decode(parts[1])),
      );
    }
    if (parts.length < 3) {
      throw FirebaseBackendException(
        'Runtime host returned a malformed response.',
        details: line,
      );
    }
    return <String>[
      utf8.decode(base64Decode(parts[1])),
      utf8.decode(base64Decode(parts[2])),
    ];
  }

  FirebaseBackendConfig _requireConfig() {
    final FirebaseBackendConfig? config = _config;
    if (config == null) {
      throw FirebaseBackendException(
        'Backend must be initialized before it can be used.',
      );
    }
    return config;
  }
}
