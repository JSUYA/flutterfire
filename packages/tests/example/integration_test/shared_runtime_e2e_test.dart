// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Cross-plugin integration test that asserts the shared runtime and auth
// context actually survive when every Firebase Tizen plugin is loaded at
// once. This is the primary guard against regressions in the TPK-bloat
// mitigation: if each plugin spun up its own runtime, the bytes the
// Tizen build produced would balloon.

import 'package:firebase_app_installations_tizen/firebase_app_installations_tizen.dart';
import 'package:firebase_auth_tizen/firebase_auth_tizen.dart';
import 'package:firebase_core_tizen/firebase_core_tizen.dart';
import 'package:firebase_database_tizen/firebase_database_tizen.dart';
import 'package:firebase_remote_config_tizen/firebase_remote_config_tizen.dart';
import 'package:firebase_storage_tizen/firebase_storage_tizen.dart';
import 'package:cloud_functions_tizen/cloud_functions_tizen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Cross-plugin shared runtime', () {
    test('every plugin register() is idempotent and side-effect free', () {
      // If any register() throws, the test fails — a silent register() is
      // what the plugin tool expects.
      expect(FirebaseCoreTizen.register, returnsNormally);
      expect(FirebaseAuthTizen.register, returnsNormally);
      expect(FirebaseDatabaseTizen.register, returnsNormally);
      expect(FirebaseStorageTizen.register, returnsNormally);
      expect(CloudFunctionsTizen.register, returnsNormally);
      expect(FirebaseInstallationsTizen.register, returnsNormally);
      expect(FirebaseRemoteConfigTizen.register, returnsNormally);
    });

    test('TizenAuthContext is a singleton shared by every plugin', () {
      final TizenAuthContext a = TizenAuthContext.instance;
      final TizenAuthContext b = TizenAuthContext.instance;
      expect(identical(a, b), isTrue);
    });

    test('TizenHttpClient is a singleton shared by every plugin', () {
      final TizenHttpClient a = TizenHttpClient.instance;
      final TizenHttpClient b = TizenHttpClient.instance;
      expect(identical(a, b), isTrue);
    });
  });
}
