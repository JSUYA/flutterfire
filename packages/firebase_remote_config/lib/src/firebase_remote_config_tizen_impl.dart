// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:firebase_app_installations_tizen/firebase_app_installations_tizen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config_platform_interface/firebase_remote_config_platform_interface.dart';

import 'remote_config_rest_client.dart';

/// Tizen implementation of [FirebaseRemoteConfigPlatform].
class FirebaseRemoteConfigTizen extends FirebaseRemoteConfigPlatform {
  /// Private constructor; consumers use the upstream
  /// `FirebaseRemoteConfig.instance` accessor.
  FirebaseRemoteConfigTizen._({FirebaseApp? app}) : super(appInstance: app);

  /// Entry point registered via
  /// `dartPluginClass: FirebaseRemoteConfigTizen`.
  static void register() {
    FirebaseRemoteConfigPlatform.instance = FirebaseRemoteConfigTizen._();
  }

  final Map<String, RemoteConfigValue> _parameters =
      <String, RemoteConfigValue>{};
  final Map<String, Object?> _defaults = <String, Object?>{};
  FirebaseInstallationsTizen? _installationsCache;
  RemoteConfigSettings _settings = RemoteConfigSettings(
    fetchTimeout: const Duration(minutes: 1),
    minimumFetchInterval: const Duration(hours: 12),
  );
  DateTime _lastFetch = DateTime.fromMillisecondsSinceEpoch(0);
  RemoteConfigFetchStatus _status = RemoteConfigFetchStatus.noFetchYet;
  String? _etag;
  RemoteConfigRestClient? _client;

  RemoteConfigRestClient get _restClient {
    _client ??= RemoteConfigRestClient(
      apiKey: appInstance?.options.apiKey ?? '',
      projectId: appInstance?.options.projectId ?? '',
      appId: appInstance?.options.appId ?? '',
    );
    return _client!;
  }

  FirebaseInstallationsTizen get _installations {
    final FirebaseInstallationsTizen? cached = _installationsCache;
    if (cached != null) {
      return cached;
    }
    final FirebaseApp? app = appInstance;
    final FirebaseInstallationsTizen resolved = app == null
        ? FirebaseInstallationsTizen.internalForApp(Firebase.app())
        : FirebaseInstallationsTizen.internalForApp(app);
    _installationsCache = resolved;
    return resolved;
  }

  @override
  FirebaseRemoteConfigPlatform delegateFor({required FirebaseApp app}) {
    return FirebaseRemoteConfigTizen._(app: app);
  }

  @override
  FirebaseRemoteConfigPlatform setInitialValues({
    required Map<dynamic, dynamic> remoteConfigValues,
  }) {
    remoteConfigValues.forEach((Object? key, Object? value) {
      if (key is String && value is Map<String, Object?>) {
        _parameters[key] = _valueFromMap(value);
      }
    });
    return this;
  }

  @override
  Future<bool> activate() async {
    // Values are applied immediately on fetch; activate is a no-op here but
    // still reports the upstream expectation.
    return true;
  }

  @override
  Future<void> ensureInitialized() async {}

  @override
  Future<bool> fetchAndActivate() async {
    await fetch();
    return activate();
  }

  @override
  Future<void> fetch() async {
    if (DateTime.now().difference(_lastFetch) < _settings.minimumFetchInterval) {
      _status = RemoteConfigFetchStatus.throttle;
      return;
    }
    try {
      final String installationId =
          await _installations.getId();
      final String installationToken = await _installations.getToken();
      final RemoteConfigFetchResponse response = await _restClient.fetch(
        installationId: installationId,
        installationToken: installationToken,
        etag: _etag,
      );
      if (!response.notModified) {
        _parameters.clear();
        response.entries.forEach((String key, Object? value) {
          _parameters[key] = _valueFromString(value);
        });
        _etag = response.etag;
      }
      _lastFetch = DateTime.now();
      _status = RemoteConfigFetchStatus.success;
    } catch (_) {
      _status = RemoteConfigFetchStatus.failure;
      rethrow;
    }
  }

  @override
  Map<String, RemoteConfigValue> getAll() {
    return <String, RemoteConfigValue>{..._parameters};
  }

  @override
  bool getBool(String key) => getValue(key).asBool();

  @override
  int getInt(String key) => getValue(key).asInt();

  @override
  double getDouble(String key) => getValue(key).asDouble();

  @override
  String getString(String key) => getValue(key).asString();

  @override
  RemoteConfigValue getValue(String key) {
    return _parameters[key] ?? _defaultsToValue(key);
  }

  @override
  DateTime get lastFetchTime => _lastFetch;

  @override
  RemoteConfigFetchStatus get lastFetchStatus => _status;

  @override
  RemoteConfigSettings get settings => _settings;

  @override
  Future<void> setConfigSettings(RemoteConfigSettings remoteConfigSettings) async {
    _settings = remoteConfigSettings;
  }

  @override
  Future<void> setDefaults(Map<String, Object?> defaults) async {
    _defaults
      ..clear()
      ..addAll(defaults);
  }

  @override
  Stream<RemoteConfigUpdate> get onConfigUpdated {
    return Stream<RemoteConfigUpdate>.error(
      UnimplementedError(
        'onConfigUpdated is not supported by firebase_remote_config_tizen. '
        'Reason: the realtime Remote Config protocol keeps a long-lived '
        'connection open, which Tizen TV drops aggressively in standby. '
        'Call fetchAndActivate() manually on app foreground instead.',
      ),
    );
  }

  /// Converts an arbitrary value into the UTF-8 byte list that
  /// RemoteConfigValue expects. String.codeUnits is UTF-16 and would
  /// corrupt every non-ASCII value when the consumer calls asString().
  List<int> _bytesOf(Object? value) {
    if (value == null) {
      return const <int>[];
    }
    if (value is List<int>) {
      return value;
    }
    return utf8.encode(value.toString());
  }

  RemoteConfigValue _valueFromMap(Map<String, Object?> json) {
    final Object? source = json['source'];
    final ValueSource src = switch (source) {
      'remote' => ValueSource.valueRemote,
      'default' => ValueSource.valueDefault,
      _ => ValueSource.valueStatic,
    };
    final Object? value = json['value'];
    if (value == null) {
      return RemoteConfigValue(null, src);
    }
    return RemoteConfigValue(_bytesOf(value), src);
  }

  RemoteConfigValue _valueFromString(Object? raw) {
    if (raw == null) {
      return RemoteConfigValue(null, ValueSource.valueRemote);
    }
    return RemoteConfigValue(_bytesOf(raw), ValueSource.valueRemote);
  }

  RemoteConfigValue _defaultsToValue(String key) {
    if (!_defaults.containsKey(key)) {
      return RemoteConfigValue(null, ValueSource.valueStatic);
    }
    final Object? raw = _defaults[key];
    if (raw == null) {
      return RemoteConfigValue(null, ValueSource.valueDefault);
    }
    return RemoteConfigValue(_bytesOf(raw), ValueSource.valueDefault);
  }
}
