// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_tizen/firebase_core_tizen.dart';
import 'package:firebase_storage_platform_interface/firebase_storage_platform_interface.dart';

import 'reference_tizen.dart';
import 'storage_rest_client.dart';

/// Tizen implementation of [FirebaseStoragePlatform].
class FirebaseStorageTizen extends FirebaseStoragePlatform {
  /// Private constructor used by [register] and [delegateFor].
  FirebaseStorageTizen._({
    FirebaseApp? app,
    required String bucket,
  })  : _client = StorageRestClient(
          bucket: bucket,
          appName: app?.name ?? defaultFirebaseAppName,
        ),
        super(appInstance: app, bucket: bucket);

  /// Entry point registered via `dartPluginClass: FirebaseStorageTizen` in
  /// `pubspec.yaml`.
  static void register() {
    FirebaseStoragePlatform.instance = FirebaseStorageTizen._(
      bucket: '',
    );
  }

  final StorageRestClient _client;

  /// REST client shared with [ReferenceTizen] and task drivers.
  StorageRestClient get client => _client;

  @override
  FirebaseStoragePlatform delegateFor({
    FirebaseApp? app,
    required String bucket,
  }) {
    final String effectiveBucket = bucket.isNotEmpty
        ? bucket
        : app?.options.storageBucket ?? '';
    return FirebaseStorageTizen._(app: app, bucket: effectiveBucket);
  }

  @override
  ReferencePlatform ref(String path) {
    return ReferenceTizen(this, path);
  }

  @override
  int get maxDownloadRetryTime => _maxDownloadRetryMillis;

  @override
  int get maxOperationRetryTime => _maxOperationRetryMillis;

  @override
  int get maxUploadRetryTime => _maxUploadRetryMillis;

  int _maxDownloadRetryMillis = 600000;
  int _maxOperationRetryMillis = 120000;
  int _maxUploadRetryMillis = 600000;

  @override
  void setMaxDownloadRetryTime(int time) {
    _maxDownloadRetryMillis = time;
  }

  @override
  void setMaxOperationRetryTime(int time) {
    _maxOperationRetryMillis = time;
  }

  @override
  void setMaxUploadRetryTime(int time) {
    _maxUploadRetryMillis = time;
  }

  @override
  Future<void> useStorageEmulator(String host, int port) {
    throw UnimplementedError(
      'useStorageEmulator is not supported by firebase_storage_tizen. '
      'Reason: the emulator uses loopback TLS that Tizen TV devices do not '
      'trust.',
    );
  }
}
