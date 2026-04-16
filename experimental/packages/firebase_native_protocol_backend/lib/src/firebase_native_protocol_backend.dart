import 'dart:convert';
import 'dart:io';

import 'package:firebase_backend_contract/firebase_backend_contract.dart';

class FirebaseNativeProtocolBackend implements FirebaseExperimentalBackend {
  FirebaseNativeProtocolBackend({
    required this.binaryPath,
  });

  final String binaryPath;

  FirebaseBackendConfig? _config;
  String? _idToken;

  @override
  Future<void> initialize(FirebaseBackendConfig config) async {
    _config = config;
  }

  @override
  Future<FirebaseUserSession> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final FirebaseBackendConfig config = _requireConfig();
    final _NativeResponse response = await _runCommand(
      'sign-in',
      url: config.buildSignInUrl(),
      body: jsonEncode(<String, Object?>{
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
    );
    final Map<String, Object?> payload =
        jsonDecode(response.body) as Map<String, Object?>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FirebaseBackendException(
        'Sign-in failed with HTTP ${response.statusCode}',
        details: payload,
      );
    }
    final FirebaseUserSession session = FirebaseUserSession.fromJson(payload);
    _idToken = session.idToken;
    return session;
  }

  @override
  Future<Object?> callFunction(
    String name, {
    Object? data,
    String region = 'us-central1',
  }) async {
    final FirebaseBackendConfig config = _requireConfig();
    final _NativeResponse response = await _runCommand(
      'callable',
      url: config.buildCallableUrl(name, region: region),
      body: jsonEncode(<String, Object?>{'data': data}),
      bearer: _idToken,
    );
    final Map<String, Object?> payload =
        jsonDecode(response.body) as Map<String, Object?>;
    if (payload['error'] case final Map<String, Object?> error) {
      throw FirebaseBackendException(
        (error['message'] ?? 'Callable request failed.') as String,
        details: error['details'],
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FirebaseBackendException(
        'Callable failed with HTTP ${response.statusCode}',
        details: payload,
      );
    }
    return payload['result'] ?? payload['data'] ?? payload['response'];
  }

  @override
  Future<void> dispose() async {}

  Future<_NativeResponse> _runCommand(
    String command, {
    required String url,
    required String body,
    String? bearer,
  }) async {
    final List<String> arguments = <String>[
      command,
      '--url',
      url,
      '--body-base64',
      base64Encode(utf8.encode(body)),
      if (bearer != null) ...<String>[
        '--bearer',
        bearer,
      ],
    ];

    final ProcessResult processResult = await Process.run(binaryPath, arguments);
    final String stdoutText = processResult.stdout as String;
    final Map<String, String> responseParts = <String, String>{};
    for (final String line in const LineSplitter().convert(stdoutText)) {
      final int separator = line.indexOf('\t');
      if (separator == -1) {
        continue;
      }
      responseParts[line.substring(0, separator)] = line.substring(separator + 1);
    }

    final String errorText = utf8.decode(
      base64Decode(responseParts['ERROR'] ?? ''),
      allowMalformed: true,
    );
    if (processResult.exitCode != 0 && errorText.isNotEmpty) {
      throw FirebaseBackendException(errorText);
    }

    return _NativeResponse(
      statusCode: int.parse(responseParts['STATUS'] ?? '0'),
      body: utf8.decode(base64Decode(responseParts['BODY'] ?? '')),
    );
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

class _NativeResponse {
  const _NativeResponse({
    required this.statusCode,
    required this.body,
  });

  final int statusCode;
  final String body;
}
