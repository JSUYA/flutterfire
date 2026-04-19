// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_dart/firebase_dart.dart' as fd;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:synchronized/synchronized.dart';

import 'firebase_dart_conversions.dart';

/// Process-wide owner of the `firebase_dart` runtime used by every Firebase
/// Tizen plugin.
///
/// The runtime is initialized exactly once via `FirebaseDart.setup(...)`; a
/// [Lock] guards the `setup` call so that concurrent `initializeApp` calls
/// from different plugins cannot double-initialize it or run the setup work
/// on the UI isolate.
///
/// Sibling Tizen plugins obtain Firebase apps through [registerApp] and
/// [dartAppFor]; they never call `firebase_dart` directly so that the shared
/// isolate, persistence path, and platform descriptor remain consistent.
@internal
class FirebaseTizenRuntime {
  FirebaseTizenRuntime._();

  /// Singleton accessor.
  static final FirebaseTizenRuntime instance = FirebaseTizenRuntime._();

  final Lock _setupLock = Lock();
  final Map<String, fd.FirebaseApp> _apps = <String, fd.FirebaseApp>{};
  bool _ready = false;

  /// The directory under the Tizen application support path where
  /// `firebase_dart` writes its persistent Hive boxes.
  String? _storagePath;

  /// Whether [ensureInitialized] has completed successfully.
  bool get isReady => _ready;

  /// Returns the `firebase_dart` storage directory; throws
  /// [StateError] before [ensureInitialized] completes.
  String get storagePath {
    final String? path = _storagePath;
    if (path == null) {
      throw StateError(
        'FirebaseTizenRuntime has not been initialized; call ensureInitialized '
        'first.',
      );
    }
    return path;
  }

  /// Initializes the `firebase_dart` runtime if it has not been set up yet.
  ///
  /// Safe to call from multiple isolate entry points; the first invocation
  /// performs the `FirebaseDart.setup` call while subsequent ones wait on the
  /// same [Lock].
  Future<void> ensureInitialized() async {
    if (_ready) {
      return;
    }
    await _setupLock.synchronized<void>(() async {
      if (_ready) {
        return;
      }
      final Directory baseDir = await getApplicationSupportDirectory();
      final String path = p.join(baseDir.path, 'firebase_tizen');
      await Directory(path).create(recursive: true);
      fd.FirebaseDart.setup(
        storagePath: path,
        isolated: true,
        platform: fd.Platform.linux(
          isOnline: true,
          isMobile: false,
        ),
      );
      _storagePath = path;
      _ready = true;
    });
  }

  /// Registers a Firebase app with the runtime and returns the underlying
  /// `firebase_dart.FirebaseApp`.
  ///
  /// When [name] is null the default app name is used, matching
  /// [FirebasePlatform.defaultFirebaseAppName].
  Future<fd.FirebaseApp> registerApp({
    String? name,
    required FirebaseOptions options,
  }) async {
    await ensureInitialized();
    final String appName = name ?? defaultFirebaseAppName;
    final fd.FirebaseApp existing = _apps[appName] ??
        await _initializeDartApp(name: appName, options: options);
    _apps[appName] = existing;
    return existing;
  }

  Future<fd.FirebaseApp> _initializeDartApp({
    required String appName,
    required FirebaseOptions options,
  }) async {
    final fd.FirebaseOptions dartOptions =
        FirebaseDartOptionsConversions.toDart(options);
    if (appName == defaultFirebaseAppName) {
      return fd.Firebase.initializeApp(options: dartOptions);
    }
    return fd.Firebase.initializeApp(name: appName, options: dartOptions);
  }

  /// Returns the `firebase_dart` app registered under [name], or throws
  /// [FirebaseException] if the app is unknown.
  fd.FirebaseApp dartAppFor(String name) {
    final fd.FirebaseApp? app = _apps[name];
    if (app == null) {
      throw FirebaseException(
        plugin: 'firebase_core',
        code: 'no-app',
        message:
            'No Firebase App "$name" has been created - call Firebase.initializeApp()',
      );
    }
    return app;
  }

  /// Returns the list of registered app names in registration order.
  List<String> registeredAppNames() => _apps.keys.toList(growable: false);

  /// Removes [name] from the registry, calling `delete` on the underlying
  /// `firebase_dart` app.
  Future<void> deleteApp(String name) async {
    final fd.FirebaseApp? app = _apps.remove(name);
    if (app == null) {
      return;
    }
    await app.delete();
  }

  /// Test-only reset hook.
  @visibleForTesting
  Future<void> resetForTesting() async {
    _apps.clear();
    _ready = false;
    _storagePath = null;
  }
}
