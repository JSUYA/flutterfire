// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_dart/firebase_dart.dart' as fd;
import 'package:meta/meta.dart';

/// Converts between upstream `FirebaseOptions` and the `firebase_dart`
/// equivalents.
///
/// `firebase_dart.FirebaseOptions` uses a slightly narrower schema than
/// `firebase_core`'s, so the conversions keep the optional fields intact and
/// refuse to fabricate identifiers (e.g., never coerce a missing sender id
/// into an empty string).
@internal
class FirebaseDartOptionsConversions {
  /// Map a FlutterFire [FirebaseOptions] to its `firebase_dart` counterpart.
  static fd.FirebaseOptions toDart(FirebaseOptions options) {
    return fd.FirebaseOptions(
      apiKey: options.apiKey,
      appId: options.appId,
      messagingSenderId: options.messagingSenderId,
      projectId: options.projectId,
      authDomain: options.authDomain,
      databaseURL: options.databaseURL,
      storageBucket: options.storageBucket,
      measurementId: options.measurementId,
      trackingId: options.trackingId,
      deepLinkURLScheme: options.deepLinkURLScheme,
      androidClientId: options.androidClientId,
      iosClientId: options.iosClientId,
      iosBundleId: options.iosBundleId,
      appGroupId: options.appGroupId,
    );
  }

  /// Map a `firebase_dart` [fd.FirebaseOptions] back to the FlutterFire type.
  ///
  /// Throws [ArgumentError] when the source lacks a `messagingSenderId` —
  /// FlutterFire's `FirebaseOptions.messagingSenderId` is non-nullable, and
  /// per the class docstring we refuse to fabricate identifiers.
  static FirebaseOptions fromDart(fd.FirebaseOptions options) {
    final String? senderId = options.messagingSenderId;
    if (senderId == null) {
      throw ArgumentError.value(
        options,
        'options',
        'firebase_dart FirebaseOptions.messagingSenderId was null; '
            'FlutterFire requires a non-null messagingSenderId.',
      );
    }
    return FirebaseOptions(
      apiKey: options.apiKey,
      appId: options.appId,
      messagingSenderId: senderId,
      projectId: options.projectId,
      authDomain: options.authDomain,
      databaseURL: options.databaseURL,
      storageBucket: options.storageBucket,
      measurementId: options.measurementId,
      trackingId: options.trackingId,
      deepLinkURLScheme: options.deepLinkURLScheme,
      androidClientId: options.androidClientId,
      iosClientId: options.iosClientId,
      iosBundleId: options.iosBundleId,
      appGroupId: options.appGroupId,
    );
  }
}
