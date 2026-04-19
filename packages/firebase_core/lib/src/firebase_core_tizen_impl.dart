// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';

import 'firebase_app_tizen.dart';
import 'firebase_tizen_runtime.dart';

/// Tizen implementation of [FirebasePlatform].
///
/// The class is registered as the platform interface instance through
/// `flutter.plugin.platforms.tizen.dartPluginClass` in `pubspec.yaml`, which
/// causes the flutter-tizen plugin tool to emit a `register()` call inside
/// `GeneratedPluginRegistrant`.
class FirebaseCoreTizen extends FirebasePlatform {
  FirebaseCoreTizen._();

  /// Entry point used by `GeneratedPluginRegistrant.register` on Tizen.
  static void register() {
    FirebasePlatform.instance = FirebaseCoreTizen._();
  }

  final Map<String, FirebaseAppTizen> _appCache = <String, FirebaseAppTizen>{};

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    if (options == null) {
      throw ArgumentError.value(
        options,
        'options',
        'FirebaseOptions must be provided on Tizen; reading options from '
            'native resources is not supported.',
      );
    }
    final String appName = name ?? defaultFirebaseAppName;
    final FirebaseAppTizen? cached = _appCache[appName];
    if (cached != null) {
      if (cached.options == options) {
        return cached;
      }
      throw FirebaseException(
        plugin: 'firebase_core',
        code: 'duplicate-app',
        message:
            'A Firebase App named "$appName" already exists with different '
            'options.',
      );
    }
    await FirebaseTizenRuntime.instance.registerApp(
      name: name,
      options: options,
    );
    final FirebaseAppTizen app = FirebaseAppTizen(
      name: appName,
      options: options,
    );
    _appCache[appName] = app;
    return app;
  }

  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    final FirebaseAppTizen? cached = _appCache[name];
    if (cached != null) {
      return cached;
    }
    throw FirebaseException(
      plugin: 'firebase_core',
      code: 'no-app',
      message:
          'No Firebase App "$name" has been created - call Firebase.initializeApp()',
    );
  }

  @override
  List<FirebaseAppPlatform> get apps =>
      List<FirebaseAppPlatform>.unmodifiable(_appCache.values);
}
