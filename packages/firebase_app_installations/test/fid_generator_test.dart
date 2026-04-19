// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_app_installations_tizen/firebase_app_installations_tizen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FidGenerator', () {
    final FidGenerator generator = FidGenerator();

    test('generated FIDs match the firebase_js_sdk regex', () {
      for (int i = 0; i < 1000; i++) {
        final String fid = generator.generate();
        expect(
          FidGenerator.isValid(fid),
          isTrue,
          reason: '$fid did not match ^[cdef][A-Za-z0-9_-]{21}\$',
        );
      }
    });

    test('10k samples produce zero collisions', () {
      final Set<String> seen = <String>{};
      for (int i = 0; i < 10000; i++) {
        expect(seen.add(generator.generate()), isTrue);
      }
    });

    test('length is exactly 22 characters', () {
      for (int i = 0; i < 100; i++) {
        expect(generator.generate().length, 22);
      }
    });
  });
}
