// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_auth_tizen/src/auth_error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthErrorMapper.resolveCode', () {
    test('resolves every documented identity-toolkit code', () {
      const Map<String, String> cases = <String, String>{
        'EMAIL_NOT_FOUND': 'user-not-found',
        'INVALID_PASSWORD': 'wrong-password',
        'USER_DISABLED': 'user-disabled',
        'USER_NOT_FOUND': 'user-not-found',
        'EMAIL_EXISTS': 'email-already-in-use',
        'OPERATION_NOT_ALLOWED': 'operation-not-allowed',
        'TOO_MANY_ATTEMPTS_TRY_LATER': 'too-many-requests',
        'WEAK_PASSWORD': 'weak-password',
        'INVALID_EMAIL': 'invalid-email',
        'MISSING_EMAIL': 'invalid-email',
        'INVALID_ID_TOKEN': 'user-token-expired',
        'TOKEN_EXPIRED': 'user-token-expired',
        'INVALID_REFRESH_TOKEN': 'invalid-user-token',
        'MISSING_REFRESH_TOKEN': 'invalid-user-token',
        'INVALID_CUSTOM_TOKEN': 'invalid-custom-token',
        'CUSTOM_TOKEN_MISMATCH': 'custom-token-mismatch',
        'CREDENTIAL_TOO_OLD_LOGIN_AGAIN': 'requires-recent-login',
        'EXPIRED_OOB_CODE': 'expired-action-code',
        'INVALID_OOB_CODE': 'invalid-action-code',
        'INVALID_IDP_RESPONSE': 'invalid-credential',
        'FEDERATED_USER_ID_ALREADY_LINKED': 'credential-already-in-use',
      };
      cases.forEach((String raw, String expected) {
        expect(
          AuthErrorMapper.resolveCode(raw),
          expected,
          reason: 'Unexpected mapping for "$raw"',
        );
      });
    });

    test('falls back to a kebab-cased lower form for unknown codes', () {
      expect(
        AuthErrorMapper.resolveCode('SOME_UNKNOWN_CODE'),
        'some-unknown-code',
      );
    });

    test('null input resolves to "unknown"', () {
      expect(AuthErrorMapper.resolveCode(null), 'unknown');
    });
  });

  group('AuthErrorMapper.map', () {
    test('passes through an existing FirebaseAuthException', () {
      final FirebaseAuthException input = FirebaseAuthException(
        code: 'user-disabled',
        message: 'Disabled',
      );
      final FirebaseAuthException mapped =
          AuthErrorMapper.map(input, StackTrace.current);
      expect(identical(mapped, input), isTrue);
    });

    test('maps an arbitrary error with an uppercase code in its text', () {
      final Object error = Exception('EMAIL_EXISTS: already taken');
      final FirebaseAuthException mapped =
          AuthErrorMapper.map(error, StackTrace.current);
      expect(mapped.code, 'email-already-in-use');
      expect(mapped.message, contains('EMAIL_EXISTS'));
    });

    test('falls back to "unknown" when the error string has no code', () {
      final FirebaseAuthException mapped =
          AuthErrorMapper.map('???', StackTrace.current);
      expect(mapped.code, 'unknown');
    });
  });
}
