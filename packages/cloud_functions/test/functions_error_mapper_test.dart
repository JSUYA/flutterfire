// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cloud_functions_platform_interface/cloud_functions_platform_interface.dart';
import 'package:cloud_functions_tizen/cloud_functions_tizen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FunctionsErrorMapper', () {
    test('maps canonical status strings to kebab-case gRPC codes', () {
      const Map<String, String> cases = <String, String>{
        'CANCELLED': 'cancelled',
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
        'UNKNOWN': 'unknown',
      };
      cases.forEach((String rawStatus, String expected) {
        final FirebaseFunctionsException exception =
            FunctionsErrorMapper.map(
          statusCode: 400,
          payload: <String, Object?>{
            'error': <String, Object?>{
              'status': rawStatus,
              'message': 'boom',
              'details': <Object?>[rawStatus],
            }
          },
        );
        expect(exception.code, expected);
        expect(exception.message, 'boom');
        expect(exception.details, <Object?>[rawStatus]);
      });
    });

    test('falls back to HTTP-status-based code when payload has no status',
        () {
      expect(
        FunctionsErrorMapper.map(statusCode: 403).code,
        'unauthenticated',
      );
      expect(
        FunctionsErrorMapper.map(statusCode: 502).code,
        'unavailable',
      );
      expect(
        FunctionsErrorMapper.map(statusCode: 599).code,
        'unknown',
      );
    });
  });

  group('CallableCodec', () {
    const CallableCodec codec = CallableCodec();

    test('Int64 above 2^53 is wrapped and round-tripped', () {
      const int big = 9223372036854775000;
      final Object? encoded = codec.encode(big);
      expect(encoded, isA<Map<String, Object?>>());
      expect(
        (encoded as Map<String, Object?>)['@type'],
        'type.googleapis.com/google.protobuf.Int64Value',
      );
      expect(codec.decode(encoded), big);
    });

    test('Nested structures round-trip', () {
      final Object? encoded = codec.encode(<String, Object?>{
        'a': <Object?>[1, 2, 'x'],
        'b': <String, Object?>{'c': 3},
      });
      expect(codec.decode(encoded), <String, Object?>{
        'a': <Object?>[1, 2, 'x'],
        'b': <String, Object?>{'c': 3},
      });
    });
  });
}
