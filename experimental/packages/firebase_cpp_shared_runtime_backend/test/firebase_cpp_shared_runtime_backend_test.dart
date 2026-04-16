import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_backend_contract/firebase_backend_contract.dart';
import 'package:firebase_cpp_shared_runtime_backend/firebase_cpp_shared_runtime_backend.dart';
import 'package:test/test.dart';

void main() {
  group('FirebaseCppSharedRuntimeBackend', () {
    late _FakeFirebaseServer server;

    setUp(() async {
      server = await _FakeFirebaseServer.start();
    });

    tearDown(() async {
      await server.close();
    });

    test('signs in and calls a callable through the shared runtime host', () async {
      final FirebaseCppSharedRuntimeBackend backend =
          FirebaseCppSharedRuntimeBackend(
        binaryPath: File('../../native/build/firebase_runtime_host').absolute.path,
      );

      await backend.initialize(
        FirebaseBackendConfig(
          apiKey: 'test-api-key',
          projectId: 'test-project',
          authBaseUrl: '${server.baseUrl}/identitytoolkit',
          functionsBaseUrl: '${server.baseUrl}/functions',
        ),
      );

      final FirebaseUserSession session =
          await backend.signInWithEmailAndPassword(
        'user@example.com',
        'secret',
      );

      expect(session.idToken, 'token-123');
      expect(session.email, 'user@example.com');

      final Object? result = await backend.callFunction(
        'echo',
        data: <String, Object?>{'value': 42},
      );

      expect(
        result,
        <String, Object?>{
          'message': 'ok',
          'echo': <String, Object?>{'value': 42},
        },
      );

      await backend.dispose();
    });
  });
}

class _FakeFirebaseServer {
  _FakeFirebaseServer(this._server);

  final HttpServer _server;

  static Future<_FakeFirebaseServer> start() async {
    final HttpServer server = await HttpServer.bind('127.0.0.1', 0);
    final _FakeFirebaseServer fakeServer = _FakeFirebaseServer(server);
    unawaited(fakeServer._serve());
    return fakeServer;
  }

  String get baseUrl => 'http://${_server.address.host}:${_server.port}';

  Future<void> close() => _server.close(force: true);

  Future<void> _serve() async {
    await for (final HttpRequest request in _server) {
      if (request.uri.path == '/identitytoolkit/accounts:signInWithPassword') {
        await _handleSignIn(request);
        continue;
      }
      if (request.uri.path == '/functions/test-project/us-central1/echo') {
        await _handleCallable(request);
        continue;
      }

      request.response
        ..statusCode = HttpStatus.notFound
        ..write('not found');
      await request.response.close();
    }
  }

  Future<void> _handleSignIn(HttpRequest request) async {
    final Map<String, Object?> body =
        jsonDecode(await utf8.decoder.bind(request).join()) as Map<String, Object?>;
    expect(body['email'], 'user@example.com');
    expect(body['password'], 'secret');

    request.response.headers.contentType = ContentType.json;
    request.response.write(
      jsonEncode(<String, Object?>{
        'idToken': 'token-123',
        'refreshToken': 'refresh-123',
        'localId': 'user-123',
        'email': 'user@example.com',
      }),
    );
    await request.response.close();
  }

  Future<void> _handleCallable(HttpRequest request) async {
    expect(request.headers.value(HttpHeaders.authorizationHeader), 'Bearer token-123');
    final Map<String, Object?> body =
        jsonDecode(await utf8.decoder.bind(request).join()) as Map<String, Object?>;

    request.response.headers.contentType = ContentType.json;
    request.response.write(
      jsonEncode(<String, Object?>{
        'result': <String, Object?>{
          'message': 'ok',
          'echo': body['data'],
        },
      }),
    );
    await request.response.close();
  }
}
