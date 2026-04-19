// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_tizen/firebase_core_tizen.dart';
import 'package:firebase_database_platform_interface/firebase_database_platform_interface.dart';
import 'package:firebase_dart/firebase_dart.dart' as fd;

import 'database_reference_tizen.dart';

/// Tizen implementation of [DatabasePlatform].
class FirebaseDatabaseTizen extends DatabasePlatform {
  /// Private constructor used by [register] and [delegateFor].
  FirebaseDatabaseTizen._({FirebaseApp? app, String? databaseURL})
      : super(app: app, databaseURL: databaseURL);

  /// Entry point wired via `dartPluginClass: FirebaseDatabaseTizen` in
  /// `pubspec.yaml`.
  static void register() {
    DatabasePlatform.instance = FirebaseDatabaseTizen._();
  }

  /// Exposed to sibling classes (reference/snapshot) so they can resolve a
  /// fresh `firebase_dart.FirebaseDatabase` for the current app.
  fd.FirebaseDatabase get dartDatabase {
    final String appName = app?.name ?? defaultFirebaseAppName;
    return fd.FirebaseDatabase(
      app: FirebaseTizenRuntime.instance.dartAppFor(appName),
      databaseURL: databaseURL,
    );
  }

  @override
  DatabasePlatform delegateFor({
    FirebaseApp? app,
    String? databaseURL,
  }) {
    return FirebaseDatabaseTizen._(app: app, databaseURL: databaseURL);
  }

  @override
  DatabaseReferencePlatform ref([String? path]) {
    final fd.DatabaseReference reference = path == null
        ? dartDatabase.reference()
        : dartDatabase.reference().child(path);
    return DatabaseReferenceTizen(this, reference);
  }

  @override
  DatabaseReferencePlatform refFromURL(String url) {
    // Firebase Realtime Database URLs look like
    //   https://<db>.firebaseio.com/path/to/node
    // or
    //   https://<db>.<region>.firebasedatabase.app/path/to/node
    // Extract the path portion so the resulting reference points at the
    // target node (not at '%2Fhttps%3A%2F%2F...').
    final Uri parsed = Uri.parse(url);
    final String path = parsed.path.startsWith('/')
        ? parsed.path.substring(1)
        : parsed.path;
    final fd.FirebaseDatabase resolved = fd.FirebaseDatabase(
      app: dartDatabase.app,
      databaseURL: '${parsed.scheme}://${parsed.authority}',
    );
    final fd.DatabaseReference reference = path.isEmpty
        ? resolved.reference()
        : resolved.reference().child(path);
    return DatabaseReferenceTizen(this, reference);
  }

  @override
  void useDatabaseEmulator(String host, int port) {
    throw UnimplementedError(
      'useDatabaseEmulator is not supported by firebase_database_tizen. '
      'Reason: the emulator relies on loopback TLS that Tizen TV devices do '
      'not trust.',
    );
  }

  @override
  void setPersistenceEnabled(bool enabled) {
    if (!enabled) {
      return;
    }
    throw UnimplementedError(
      'setPersistenceEnabled(true) is not supported by '
      'firebase_database_tizen. Reason: firebase_dart has an unresolved '
      'persistence-growth bug (#63); on-disk caches inflate without bound, '
      'which is unsafe on Tizen TV storage budgets.',
    );
  }

  @override
  void setPersistenceCacheSizeBytes(int cacheSize) {
    throw UnimplementedError(
      'setPersistenceCacheSizeBytes is not supported by '
      'firebase_database_tizen. Reason: on-disk persistence is disabled; '
      'see setPersistenceEnabled for details.',
    );
  }

  @override
  void setLoggingEnabled(bool enabled) {
    fd.FirebaseDatabase.setLoggingEnabled(enabled);
  }

  @override
  Future<void> goOnline() async {
    dartDatabase.goOnline();
  }

  @override
  Future<void> goOffline() async {
    dartDatabase.goOffline();
  }

  @override
  Future<void> purgeOutstandingWrites() async {
    // firebase_dart flushes writes automatically on reconnect; there is no
    // queue to purge. Treat as a documented no-op.
  }
}
