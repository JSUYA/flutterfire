// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_dart/firebase_dart.dart' as fd;
import 'package:meta/meta.dart';

/// Maps Firebase Auth REST error codes — surfaced by `firebase_dart` as
/// either its own [fd.FirebaseAuthException] or the identity-toolkit
/// `errorMessage` string — onto the canonical FlutterFire codes.
///
/// Keeping this table central makes it the single enforcement point for
/// Auth error-code parity; the [resolveCode] table is covered by
/// `test/auth_error_mapper_test.dart`.
@internal
class AuthErrorMapper {
  /// Converts any `firebase_dart` or REST Auth error to a
  /// [FirebaseAuthException] with a canonical [FirebaseAuthException.code].
  static FirebaseAuthException map(Object error, StackTrace stackTrace) {
    if (error is FirebaseAuthException) {
      return error;
    }
    final String? rawCode = _extractRawCode(error);
    final String code = resolveCode(rawCode);
    final String message = _extractMessage(error) ??
        'Firebase Auth request failed (code=$code).';
    return FirebaseAuthException(
      code: code,
      message: message,
    );
  }

  /// Translates a raw Firebase Auth REST code (e.g. `EMAIL_NOT_FOUND`) to
  /// the FlutterFire canonical code (`user-not-found`).
  ///
  /// Returns `'unknown'` for unrecognised or `null` input.
  static String resolveCode(String? raw) {
    if (raw == null) {
      return 'unknown';
    }
    final String? mapped = _codeMap[raw.toUpperCase()];
    return mapped ?? _fallback(raw);
  }

  static String _fallback(String raw) {
    final String normalized = raw.replaceAll('_', '-').toLowerCase();
    return normalized;
  }

  static String? _extractRawCode(Object error) {
    if (error is fd.FirebaseAuthException) {
      return error.code;
    }
    final String message = error.toString();
    final RegExpMatch? match =
        RegExp(r'([A-Z][A-Z0-9_]+)').firstMatch(message);
    return match?.group(1);
  }

  static String? _extractMessage(Object error) {
    if (error is fd.FirebaseAuthException) {
      return error.message;
    }
    return error.toString();
  }

  static const Map<String, String> _codeMap = <String, String>{
    'EMAIL_NOT_FOUND': 'user-not-found',
    'EMAIL_EXISTS': 'email-already-in-use',
    'EMAIL_ALREADY_IN_USE': 'email-already-in-use',
    'INVALID_PASSWORD': 'wrong-password',
    'INVALID_LOGIN_CREDENTIALS': 'invalid-credential',
    'INVALID_EMAIL': 'invalid-email',
    'USER_DISABLED': 'user-disabled',
    'USER_NOT_FOUND': 'user-not-found',
    'OPERATION_NOT_ALLOWED': 'operation-not-allowed',
    'TOO_MANY_ATTEMPTS_TRY_LATER': 'too-many-requests',
    'WEAK_PASSWORD': 'weak-password',
    'MISSING_EMAIL': 'invalid-email',
    'MISSING_PASSWORD': 'wrong-password',
    'MISSING_PHONE_NUMBER': 'missing-phone-number',
    'INVALID_PHONE_NUMBER': 'invalid-phone-number',
    'MISSING_CODE': 'missing-verification-code',
    'INVALID_CODE': 'invalid-verification-code',
    'MISSING_SESSION_INFO': 'missing-verification-id',
    'INVALID_SESSION_INFO': 'invalid-verification-id',
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
    'EMAIL_CHANGE_NEEDS_VERIFICATION': 'email-change-needs-verification',
    'CAPTCHA_CHECK_FAILED': 'captcha-check-failed',
    'RESET_PASSWORD_EXCEED_LIMIT': 'too-many-requests',
    'QUOTA_EXCEEDED': 'quota-exceeded',
    'USER_CANCELLED': 'user-cancelled',
    'UNVERIFIED_EMAIL': 'unverified-email',
    'APP_NOT_AUTHORIZED': 'app-not-authorized',
    'CREDENTIAL_MISMATCH': 'credential-mismatch',
    'ADMIN_ONLY_OPERATION': 'admin-restricted-operation',
  };
}
