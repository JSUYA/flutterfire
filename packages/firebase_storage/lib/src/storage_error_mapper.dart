// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_tizen/firebase_core_tizen.dart';

/// Translates HTTP status codes from Firebase Storage REST into the canonical
/// Firebase Storage error codes defined in the platform interface.
class StorageErrorMapper {
  /// Maps an HTTP [statusCode] and optional server [code]/[message] to a
  /// [FirebaseException] with `plugin: 'firebase_storage'` and the
  /// canonical upstream code string.
  static FirebaseException map(
    int statusCode, {
    String? code,
    String? message,
  }) {
    final String mapped = _statusToCode(statusCode, code);
    return FirebaseException(
      plugin: 'firebase_storage',
      code: mapped,
      message: message ?? 'Firebase Storage request failed ($statusCode).',
    );
  }

  /// Maps a [TizenFirebaseHttpException] onto a Storage [FirebaseException].
  static FirebaseException fromHttpException(TizenFirebaseHttpException e) {
    return map(e.statusCode, code: e.code, message: e.message);
  }

  static String _statusToCode(int status, String? serverCode) {
    switch (status) {
      case 400:
        return 'invalid-argument';
      case 401:
      case 403:
        return 'unauthorized';
      case 404:
        return 'object-not-found';
      case 409:
        return 'object-already-exists';
      case 412:
        return 'metadata-invalid';
      case 429:
        return 'quota-exceeded';
      case 499:
        return 'canceled';
      case 500:
      case 502:
      case 503:
      case 504:
        return 'retry-limit-exceeded';
    }
    if (serverCode != null && serverCode.isNotEmpty) {
      return serverCode.toLowerCase().replaceAll('_', '-');
    }
    return 'unknown';
  }
}
