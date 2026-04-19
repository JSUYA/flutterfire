// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_database_platform_interface/firebase_database_platform_interface.dart';
import 'package:firebase_database_tizen/firebase_database_tizen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirebaseDatabaseTizen — unsupported surface', () {
    late FirebaseDatabaseTizen database;

    setUp(() {
      FirebaseDatabaseTizen.register();
      database = DatabasePlatform.instance as FirebaseDatabaseTizen;
    });

    test('setPersistenceEnabled(true) throws with bug reference', () {
      expect(
        () => database.setPersistenceEnabled(true),
        throwsA(
          isA<UnimplementedError>().having(
            (UnimplementedError e) => e.message,
            'message',
            contains('persistence-growth'),
          ),
        ),
      );
    });

    test('setPersistenceEnabled(false) is a silent no-op', () {
      // Explicit assertion that disabling persistence does NOT throw — so
      // callers can safely opt out.
      expect(() => database.setPersistenceEnabled(false), returnsNormally);
    });

    test('setPersistenceCacheSizeBytes throws', () {
      expect(
        () => database.setPersistenceCacheSizeBytes(1024),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('useDatabaseEmulator throws', () {
      expect(
        () => database.useDatabaseEmulator('127.0.0.1', 9000),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
