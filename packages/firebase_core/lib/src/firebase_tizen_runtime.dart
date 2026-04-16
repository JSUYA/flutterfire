part of '../firebase_core_tizen.dart';

/// Shared `firebase_dart` bootstrap utilities for Tizen packages.
abstract final class FirebaseTizenRuntime {
  static Future<void>? _setupFuture;

  /// Returns true if the underlying `firebase_dart` runtime was configured.
  static bool get isConfigured => _setupFuture != null;

  /// Ensures the shared pure-Dart Firebase runtime is initialized once.
  static Future<void> ensureInitialized() {
    final Future<void>? existing = _setupFuture;
    if (existing != null) {
      return existing;
    }

    final Future<void> future = _initialize();
    _setupFuture = future;
    return future;
  }

  static Future<void> _initialize() async {
    final String storagePath =
        await PathProviderPlugin().getApplicationSupportPath();
    firebase_dart.FirebaseDart.setup(storagePath: storagePath);
  }

  /// Resolves the pure Dart Firebase app for a FlutterFire [FirebaseApp].
  static firebase_dart.FirebaseApp dartAppFor(FirebaseAppPlatform platformApp) {
    return firebase_dart.Firebase.app(platformApp.name);
  }

  /// Resolves the pure Dart Firebase app for a public FlutterFire [FirebaseApp].
  static firebase_dart.FirebaseApp dartAppForPublicApp(
    firebase_core.FirebaseApp app,
  ) {
    return firebase_dart.Firebase.app(app.name);
  }

  /// Converts FlutterFire options to `firebase_dart` options.
  static firebase_dart.FirebaseOptions toDartOptions(FirebaseOptions options) {
    return firebase_dart.FirebaseOptions(
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

  /// Converts `firebase_dart` options to FlutterFire options.
  static FirebaseOptions toPlatformOptions(
    firebase_dart.FirebaseOptions options,
  ) {
    return FirebaseOptions(
      apiKey: options.apiKey,
      appId: options.appId,
      messagingSenderId: options.messagingSenderId ?? '',
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
