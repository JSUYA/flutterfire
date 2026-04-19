// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cloud_functions_platform_interface/cloud_functions_platform_interface.dart';

/// Maps Firebase Functions callable error responses to
/// [FirebaseFunctionsException].
class FunctionsErrorMapper {
  static const Map<String, String> _canonicalCodes = <String, String>{
    'CANCELLED': 'cancelled',
    'UNKNOWN': 'unknown',
    'INVALID_ARGUMENT': 'invalid-argument',
    'DEADLINE_EXCEEDED': 'deadline-exceeded',
    'NOT_FOUND': 'not-found',
    'ALREADY_EXISTS': 'already-exists',
    'PERMISSION_DENIED': 'permission-denied',
    'RESOURCE_EXHAUSTED': 'resource-exhausted',
    'FAILED_PRECONDITION': 'failed-precondition',
    'ABORTED': 'aborted',
    'OUT_OF_RANGE': 'out-of-range',
    'UNIMPLEMENTED': 'unimplemented',
    'INTERNAL': 'internal',
    'UNAVAILABLE': 'unavailable',
    'DATA_LOSS': 'data-loss',
    'UNAUTHENTICATED': 'unauthenticated',
  };

  /// Maps an HTTP [statusCode] + server-supplied error [payload] to an
  /// exception, preserving details.
  static FirebaseFunctionsException map({
    required int statusCode,
    Map<String, Object?>? payload,
  }) {
    final Map<String, Object?>? error =
        payload?['error'] is Map<String, Object?>
            ? payload!['error'] as Map<String, Object?>
            : null;
    final String? rawStatus = error?['status'] as String?;
    final String code = _canonicalCodes[rawStatus?.toUpperCase() ?? ''] ??
        _statusCodeFallback(statusCode);
    final String message =
        error?['message'] as String? ?? 'Callable function failed.';
    return FirebaseFunctionsException(
      code: code,
      message: message,
      details: error?['details'],
    );
  }

  static String _statusCodeFallback(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'invalid-argument';
      case 401:
      case 403:
        return 'unauthenticated';
      case 404:
        return 'not-found';
      case 409:
        return 'already-exists';
      case 429:
        return 'resource-exhausted';
      case 499:
        return 'cancelled';
      case 500:
        return 'internal';
      case 502:
      case 503:
      case 504:
        return 'unavailable';
    }
    return 'unknown';
  }
}
