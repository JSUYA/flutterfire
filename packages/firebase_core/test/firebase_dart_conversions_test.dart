// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_core_tizen/firebase_core_tizen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FirebaseOptions <-> firebase_dart roundtrip preserves every field', () {
    const FirebaseOptions source = FirebaseOptions(
      apiKey: 'api',
      appId: '1:2:tizen:abc',
      messagingSenderId: '1234567890',
      projectId: 'my-project',
      authDomain: 'my-project.firebaseapp.com',
      databaseURL: 'https://my-project.firebaseio.com',
      storageBucket: 'my-project.appspot.com',
      measurementId: 'G-ABC',
      trackingId: 'UA-1',
      deepLinkURLScheme: 'myapp',
      androidClientId: 'android-client',
      iosClientId: 'ios-client',
      iosBundleId: 'com.example',
      appGroupId: 'group.com.example',
    );

    final FirebaseOptions roundtripped =
        FirebaseDartOptionsConversions.fromDart(
      FirebaseDartOptionsConversions.toDart(source),
    );

    expect(roundtripped.apiKey, source.apiKey);
    expect(roundtripped.appId, source.appId);
    expect(roundtripped.messagingSenderId, source.messagingSenderId);
    expect(roundtripped.projectId, source.projectId);
    expect(roundtripped.authDomain, source.authDomain);
    expect(roundtripped.databaseURL, source.databaseURL);
    expect(roundtripped.storageBucket, source.storageBucket);
    expect(roundtripped.measurementId, source.measurementId);
    expect(roundtripped.trackingId, source.trackingId);
    expect(roundtripped.deepLinkURLScheme, source.deepLinkURLScheme);
    expect(roundtripped.androidClientId, source.androidClientId);
    expect(roundtripped.iosClientId, source.iosClientId);
    expect(roundtripped.iosBundleId, source.iosBundleId);
    expect(roundtripped.appGroupId, source.appGroupId);
  });

  test('missing optional fields stay null (no empty-string coercion)', () {
    const FirebaseOptions minimal = FirebaseOptions(
      apiKey: 'k',
      appId: 'a',
      messagingSenderId: '1',
      projectId: 'p',
    );
    final FirebaseOptions roundtripped =
        FirebaseDartOptionsConversions.fromDart(
      FirebaseDartOptionsConversions.toDart(minimal),
    );
    expect(roundtripped.authDomain, isNull);
    expect(roundtripped.storageBucket, isNull);
    expect(roundtripped.measurementId, isNull);
  });
}
