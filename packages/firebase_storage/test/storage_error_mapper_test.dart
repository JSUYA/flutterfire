// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage_tizen/firebase_storage_tizen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StorageErrorMapper.map', () {
    test('produces firebase_storage plugin exceptions', () {
      final FirebaseException exception =
          StorageErrorMapper.map(404, message: 'Not found');
      expect(exception.plugin, 'firebase_storage');
      expect(exception.code, 'object-not-found');
      expect(exception.message, 'Not found');
    });

    test('maps standard HTTP statuses to canonical codes', () {
      const Map<int, String> expected = <int, String>{
        400: 'invalid-argument',
        401: 'unauthorized',
        403: 'unauthorized',
        404: 'object-not-found',
        409: 'object-already-exists',
        412: 'metadata-invalid',
        429: 'quota-exceeded',
        499: 'canceled',
        500: 'retry-limit-exceeded',
        502: 'retry-limit-exceeded',
        503: 'retry-limit-exceeded',
        504: 'retry-limit-exceeded',
      };
      expected.forEach((int status, String code) {
        expect(StorageErrorMapper.map(status).code, code);
      });
    });

    test('falls back to server-supplied code when status is unhandled', () {
      expect(
        StorageErrorMapper.map(418, code: 'TEAPOT_REFUSED').code,
        'teapot-refused',
      );
    });

    test('falls back to "unknown" when nothing identifies the error', () {
      expect(StorageErrorMapper.map(599).code, 'unknown');
    });
  });
}
