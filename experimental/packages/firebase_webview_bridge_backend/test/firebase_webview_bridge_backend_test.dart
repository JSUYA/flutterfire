import 'dart:io';

import 'package:firebase_backend_contract/firebase_backend_contract.dart';
import 'package:firebase_webview_bridge_backend/firebase_webview_bridge_backend.dart';
import 'package:test/test.dart';

void main() {
  group('FirebaseWebViewBridgeBackend', () {
    test('forwards initialize, sign-in, and callable commands over the bridge', () async {
      final _FakeTransport transport = _FakeTransport();
      final FirebaseWebViewBridgeBackend backend =
          FirebaseWebViewBridgeBackend(transport: transport);

      await backend.initialize(
        const FirebaseBackendConfig(
          apiKey: 'test-api-key',
          projectId: 'test-project',
          authBaseUrl: 'https://auth.example.test',
          functionsBaseUrl: 'https://functions.example.test',
        ),
      );

      final FirebaseUserSession session =
          await backend.signInWithEmailAndPassword(
        'user@example.com',
        'secret',
      );

      expect(session.idToken, 'bridge-token');

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
      expect(
        transport.commands,
        <String>['initialize', 'signInWithEmailAndPassword', 'callFunction'],
      );
    });

    test('runs the JavaScript bridge core in Node.js', () async {
      final ProcessResult result = await Process.run(
        'node',
        <String>['test/firebase_bridge_node_test.mjs'],
        runInShell: true,
      );

      expect(result.exitCode, 0, reason: result.stderr.toString());
      expect(result.stdout.toString().trim(), 'ok');
    });
  });
}

class _FakeTransport implements FirebaseWebBridgeTransport {
  final List<String> commands = <String>[];

  @override
  Future<Object?> invoke(
    String command,
    Map<String, Object?> arguments,
  ) async {
    commands.add(command);
    switch (command) {
      case 'initialize':
        return <String, Object?>{'initialized': true};
      case 'signInWithEmailAndPassword':
        return <String, Object?>{
          'idToken': 'bridge-token',
          'refreshToken': 'bridge-refresh',
          'localId': 'user-123',
          'email': arguments['email'],
        };
      case 'callFunction':
        return <String, Object?>{
          'result': <String, Object?>{
            'message': 'ok',
            'echo': arguments['data'],
          },
        };
      default:
        throw UnsupportedError(command);
    }
  }
}
