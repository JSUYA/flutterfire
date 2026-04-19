// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:firebase_app_installations_platform_interface/firebase_app_installations_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:meta/meta.dart';
import 'package:synchronized/synchronized.dart';

import 'fid_generator.dart';
import 'installations_rest_client.dart';

/// Tizen implementation of [FirebaseAppInstallationsPlatform].
///
/// The upstream abstract class is named `FirebaseAppInstallationsPlatform`
/// (with the `App` prefix); the app-facing `FirebaseInstallations` class in
/// the `firebase_app_installations` package drops the prefix, but the
/// platform interface does not.
class FirebaseInstallationsTizen extends FirebaseAppInstallationsPlatform {
  /// Private constructor; app code goes through the standard
  /// `FirebaseInstallations.instance` getter.
  FirebaseInstallationsTizen._({FirebaseApp? app}) : super(app);

  /// Entry point registered via
  /// `dartPluginClass: FirebaseInstallationsTizen`.
  static void register() {
    FirebaseAppInstallationsPlatform.instance = FirebaseInstallationsTizen._();
  }

  /// Internal factory exposed to sibling Tizen plugins (e.g. Remote Config)
  /// that need an installations delegate before `FirebaseInstallations`
  /// app-facing code has been instantiated.
  @internal
  static FirebaseInstallationsTizen internalForApp(FirebaseApp app) {
    return FirebaseInstallationsTizen._(app: app);
  }

  final Lock _lock = Lock();
  final StreamController<String> _idController =
      StreamController<String>.broadcast();
  final FidGenerator _generator = FidGenerator();
  InstallationsRestClient? _clientCache;
  String? _fid;
  InstallationsAuthToken? _token;

  InstallationsRestClient get _client {
    _clientCache ??= InstallationsRestClient(
      apiKey: app?.options.apiKey ?? '',
      projectId: app?.options.projectId ?? '',
      appId: app?.options.appId ?? '',
    );
    return _clientCache!;
  }

  @override
  FirebaseAppInstallationsPlatform delegateFor({required FirebaseApp app}) {
    return FirebaseInstallationsTizen._(app: app);
  }

  @override
  Future<void> delete() async {
    await _lock.synchronized<void>(() async {
      final String? current = _fid;
      if (current == null) {
        return;
      }
      await _client.delete(current);
      _fid = null;
      _token = null;
      _idController.add('');
    });
  }

  @override
  Future<String> getId() async {
    return _lock.synchronized<String>(_ensureFidLocked);
  }

  /// Resolves (or creates) the current FID without re-entering the lock.
  ///
  /// Callers must already hold [_lock].
  Future<String> _ensureFidLocked() async {
    final String? current = _fid;
    if (current != null) {
      return current;
    }
    final String generated = _generator.generate();
    final InstallationsAuthToken token = await _client.create(generated);
    _fid = generated;
    _token = token;
    _idController.add(generated);
    return generated;
  }

  @override
  Future<String> getToken(bool forceRefresh) async {
    return _lock.synchronized<String>(() async {
      if (!forceRefresh) {
        final InstallationsAuthToken? cached = _token;
        if (cached != null && cached.isFresh) {
          return cached.token;
        }
      }
      // Inline FID resolution so we never re-acquire the non-reentrant Lock.
      final String fid = await _ensureFidLocked();
      final InstallationsAuthToken fresh = await _client.generate(fid);
      _token = fresh;
      return fresh.token;
    });
  }

  @override
  Stream<String> get onIdChange => _idController.stream;
}
