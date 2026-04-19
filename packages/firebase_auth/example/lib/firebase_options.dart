// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_core/firebase_core.dart';

/// Placeholder Firebase options used by the example; CI rewrites this file
/// via the PRE_INSTALLER secret so the integration tests run against the
/// flutter-tizen Firebase project.
class DefaultFirebaseOptions {
  /// Hard-coded sample options; replace with the values from your own
  /// Firebase console before running on a real device.
  static const FirebaseOptions currentPlatform = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: '1:0000000000:tizen:REPLACE',
    messagingSenderId: '0000000000',
    projectId: 'flutter-tizen-firebase-demo',
    authDomain: 'flutter-tizen-firebase-demo.firebaseapp.com',
    databaseURL:
        'https://flutter-tizen-firebase-demo-default-rtdb.firebaseio.com',
    storageBucket: 'flutter-tizen-firebase-demo.appspot.com',
  );
}
