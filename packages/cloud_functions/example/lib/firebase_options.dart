/*
 * Copyright (c) 2023-present Samsung Electronics Co., Ltd
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static const String _projectId = 'flutter-tizen-firebase-demo';
  static const String _databaseUrl =
      'https://flutter-tizen-firebase-demo-default-rtdb.firebaseio.com';
  static const String _storageBucket = 'flutterfire-e2e-tests.appspot.com';

  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.linux:
        // Note: To find out if you are using the Tizen platform, refer to the link below.
        // https://github.com/flutter-tizen/flutter-tizen/issues/482#issuecomment-1441139704
        return tizen;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static String get emulatorHost {
    return const String.fromEnvironment(
      'FIREBASE_EMULATOR_HOST',
      defaultValue: 'localhost',
    );
  }

  static const FirebaseOptions tizen = FirebaseOptions(
    apiKey: 'test-api-key',
    appId: '1:0000000000:tizen:functions',
    messagingSenderId: '0000000000',
    projectId: _projectId,
    databaseURL: _databaseUrl,
    storageBucket: _storageBucket,
  );
}
