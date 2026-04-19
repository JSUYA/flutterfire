// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_core_tizen/firebase_core_tizen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const FirebaseOptions _kOptions = FirebaseOptions(
    apiKey: 'key',
    appId: 'app',
    messagingSenderId: 'sender',
    projectId: 'project',
  );

  group('FirebaseAppTizen', () {
    test('isAutomaticDataCollectionEnabled reports false (Analytics N/A)', () {
      final FirebaseAppTizen app = FirebaseAppTizen.debugCreate(
        name: '[DEFAULT]',
        options: _kOptions,
      );
      expect(app.isAutomaticDataCollectionEnabled, isFalse);
    });

    test('setAutomaticDataCollectionEnabled throws UnimplementedError', () {
      final FirebaseAppTizen app = FirebaseAppTizen.debugCreate(
        name: '[DEFAULT]',
        options: _kOptions,
      );
      expect(
        () => app.setAutomaticDataCollectionEnabled(true),
        throwsA(
          isA<UnimplementedError>().having(
            (UnimplementedError e) => e.message,
            'message',
            contains('firebase_core_tizen'),
          ),
        ),
      );
    });

    test('setAutomaticResourceManagementEnabled throws UnimplementedError',
        () {
      final FirebaseAppTizen app = FirebaseAppTizen.debugCreate(
        name: '[DEFAULT]',
        options: _kOptions,
      );
      expect(
        () => app.setAutomaticResourceManagementEnabled(true),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('preserves the platform delegate name and options identity', () {
      final FirebaseAppTizen app = FirebaseAppTizen.debugCreate(
        name: 'secondary',
        options: _kOptions,
      );
      expect(app.name, 'secondary');
      expect(identical(app.options, _kOptions), isTrue);
    });
  });
}
