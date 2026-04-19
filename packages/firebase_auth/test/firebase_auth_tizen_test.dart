// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_auth_tizen/firebase_auth_tizen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirebaseAuthTizen — unsupported surface', () {
    late FirebaseAuthTizen auth;

    setUp(() {
      // Use the private test hook to construct the platform delegate without
      // touching FirebasePlatform.instance state.
      auth = FirebaseAuthTizen.private(
        app: _FakeFirebaseApp(),
      );
    });

    test('verifyPhoneNumber throws UnimplementedError', () {
      expect(
        () => auth.verifyPhoneNumber(
          phoneNumber: '+100',
          verificationCompleted: (_) {},
          verificationFailed: (_) {},
          codeSent: (_, __) {},
          codeAutoRetrievalTimeout: (_) {},
        ),
        throwsA(isA<UnimplementedError>().having(
          (UnimplementedError e) => e.message,
          'message',
          contains('Tizen'),
        )),
      );
    });

    test('useAuthEmulator throws UnimplementedError', () {
      expect(
        () => auth.useAuthEmulator('127.0.0.1', 9099),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('setPersistence throws UnimplementedError', () {
      expect(
        () => auth.setPersistence(Persistence.LOCAL),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('signInWithEmailLink throws UnimplementedError', () {
      expect(
        () => auth.signInWithEmailLink(
          'test@example.com',
          'https://link.example',
        ),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('signInWithCredential for non-email credentials throws', () {
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: 'id',
        accessToken: 'access',
      );
      expect(
        () => auth.signInWithCredential(credential),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}

class _FakeFirebaseApp implements FirebaseApp {
  @override
  String get name => '[DEFAULT]';

  @override
  FirebaseOptions get options => const FirebaseOptions(
        apiKey: 'key',
        appId: 'app',
        messagingSenderId: '1',
        projectId: 'p',
      );

  @override
  bool get isAutomaticDataCollectionEnabled => false;

  @override
  Future<void> delete() async {}

  @override
  Future<void> setAutomaticDataCollectionEnabled(bool enabled) async {}

  @override
  Future<void> setAutomaticResourceManagementEnabled(bool enabled) async {}
}
