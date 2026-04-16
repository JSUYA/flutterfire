import 'package:firebase_backend_contract/firebase_backend_contract.dart';

import 'firebase_webview_transport.dart';

class FirebaseWebViewBridgeBackend implements FirebaseExperimentalBackend {
  FirebaseWebViewBridgeBackend({
    required FirebaseWebBridgeTransport transport,
  }) : _transport = transport;

  final FirebaseWebBridgeTransport _transport;
  FirebaseBackendConfig? _config;

  @override
  Future<void> initialize(FirebaseBackendConfig config) async {
    _config = config;
    await _transport.invoke(
      'initialize',
      config.toBridgeMap(),
    );
  }

  @override
  Future<FirebaseUserSession> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final Map<String, Object?> payload = await _invokeForMap(
      'signInWithEmailAndPassword',
      <String, Object?>{
        'email': email,
        'password': password,
      },
    );
    return FirebaseUserSession.fromJson(payload);
  }

  @override
  Future<Object?> callFunction(
    String name, {
    Object? data,
    String region = 'us-central1',
  }) async {
    final Map<String, Object?> payload = await _invokeForMap(
      'callFunction',
      <String, Object?>{
        'name': name,
        'data': data,
        'region': region,
      },
    );
    if (payload['error'] case final Map<String, Object?> error) {
      throw FirebaseBackendException(
        (error['message'] ?? 'Callable request failed.') as String,
        details: error['details'],
      );
    }
    return payload['result'] ?? payload['data'] ?? payload['response'];
  }

  @override
  Future<void> dispose() async {
    if (_config == null) {
      return;
    }
    await _transport.invoke('dispose', const <String, Object?>{});
    _config = null;
  }

  Future<Map<String, Object?>> _invokeForMap(
    String command,
    Map<String, Object?> arguments,
  ) async {
    final Object? raw = await _transport.invoke(command, arguments);
    if (raw is! Map<String, Object?>) {
      throw FirebaseBackendException(
        'WebView bridge returned an unexpected payload.',
        details: raw,
      );
    }
    return raw;
  }
}
