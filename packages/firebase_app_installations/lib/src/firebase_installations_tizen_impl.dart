// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:firebase_app_installations_platform_interface/firebase_app_installations_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:synchronized/synchronized.dart';

import 'fid_generator.dart';
import 'installations_rest_client.dart';

/// Tizen implementation of [FirebaseInstallationsPlatform].
class FirebaseInstallationsTizen extends FirebaseInstallationsPlatform {
  /// Private constructor; callers go through the standard
  /// `FirebaseInstallations.instance` getter.
  FirebaseInstallationsTizen._({FirebaseApp? app}) : super(appInstance: app);

  /// Entry point registered via
  /// `dartPluginClass: FirebaseInstallationsTizen`.
  static void register() {
    FirebaseInstallationsPlatform.instance = FirebaseInstallationsTizen._();
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
      apiKey: appInstance?.options.apiKey ?? '',
      projectId: appInstance?.options.projectId ?? '',
      appId: appInstance?.options.appId ?? '',
    );
    return _clientCache!;
  }

  @override
  FirebaseInstallationsPlatform delegateFor({required FirebaseApp app}) {
    return FirebaseInstallationsTizen._(app: app);
  }

  @override
  FirebaseInstallationsPlatform setInitialValues() {
    return this;
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
    return _lock.synchronized<String>(() async {
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
    });
  }

  @override
  Future<String> getToken([bool forceRefresh = false]) async {
    return _lock.synchronized<String>(() async {
      if (!forceRefresh) {
        final InstallationsAuthToken? cached = _token;
        if (cached != null && cached.isFresh) {
          return cached.token;
        }
      }
      final String fid = _fid ?? await getId();
      final InstallationsAuthToken fresh = await _client.generate(fid);
      _token = fresh;
      return fresh.token;
    });
  }

  @override
  Stream<String> get onIdChange => _idController.stream;
}
