library firebase_core_tizen;

import 'dart:async';

import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_dart/firebase_dart.dart' as firebase_dart;
import 'package:path_provider_tizen/path_provider_tizen.dart';

part 'src/firebase_app_tizen.dart';
part 'src/firebase_tizen_runtime.dart';

/// Tizen implementation of Firebase Core backed by `firebase_dart`.
class FirebaseCore extends FirebasePlatform {
  /// Registers this implementation as the default Firebase platform.
  static void register() {
    FirebasePlatform.instance = FirebaseCore();
  }

  FirebaseAppPlatform _mapApp(firebase_dart.FirebaseApp app) {
    return FirebaseApp._(
      app.name,
      FirebaseTizenRuntime.toPlatformOptions(app.options),
    );
  }

  @override
  List<FirebaseAppPlatform> get apps {
    if (!FirebaseTizenRuntime.isConfigured) {
      return <FirebaseAppPlatform>[];
    }

    return firebase_dart.Firebase.apps
        .map<FirebaseAppPlatform>(_mapApp)
        .toList(growable: false);
  }

  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    if (!FirebaseTizenRuntime.isConfigured) {
      throw noAppExists(name);
    }

    try {
      return _mapApp(firebase_dart.Firebase.app(name));
    } on firebase_dart.FirebaseException {
      throw noAppExists(name);
    }
  }

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    await FirebaseTizenRuntime.ensureInitialized();

    final String resolvedName = name ?? defaultFirebaseAppName;
    final FirebaseOptions resolvedOptions =
        options ?? (throw coreNotInitialized());

    try {
      final firebase_dart.FirebaseApp app =
          await firebase_dart.Firebase.initializeApp(
            name: resolvedName,
            options: FirebaseTizenRuntime.toDartOptions(resolvedOptions),
          );
      return _mapApp(app);
    } on firebase_dart.FirebaseException catch (error) {
      switch (error.code) {
        case 'no-app':
          throw noAppExists(resolvedName);
        case 'duplicate-app':
          throw duplicateApp(resolvedName);
        default:
          throw FirebaseException(
            plugin: 'firebase_core',
            code: error.code,
            message: error.message,
          );
      }
    }
  }
}
