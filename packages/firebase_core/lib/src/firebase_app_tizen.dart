// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:meta/meta.dart';

import 'firebase_tizen_runtime.dart';
import 'tizen_auth_context.dart';

/// Tizen-specific [FirebaseAppPlatform] delegate returned by
/// [FirebaseCoreTizen].
///
/// Holds no per-app Firebase state of its own — the authoritative state lives
/// in the shared [FirebaseTizenRuntime]. This class only wires the upstream
/// platform contract (`delete`, `isAutomaticDataCollectionEnabled`, …) to that
/// runtime and throws explicit `UnimplementedError`s for knobs that Firebase
/// Analytics (the only consumer) does not ship on Tizen.
class FirebaseAppTizen extends FirebaseAppPlatform {
  /// Creates a delegate for an already-registered Firebase app.
  FirebaseAppTizen({
    required String name,
    required FirebaseOptions options,
  }) : super(name, options);

  @override
  bool get isAutomaticDataCollectionEnabled {
    // Analytics is unavailable on Tizen, so the collection flag is a no-op.
    // Returning `false` is safe and truthful: no data is auto-collected.
    return false;
  }

  @override
  Future<void> delete() async {
    await FirebaseTizenRuntime.instance.deleteApp(name);
    TizenAuthContext.instance.clear(name);
  }

  @override
  Future<void> setAutomaticDataCollectionEnabled(bool enabled) async {
    throw UnimplementedError(
      'setAutomaticDataCollectionEnabled is not supported by '
      'firebase_core_tizen. Reason: Firebase Analytics is unavailable on '
      'Tizen, so there is no data collection to toggle.',
    );
  }

  @override
  Future<void> setAutomaticResourceManagementEnabled(bool enabled) async {
    throw UnimplementedError(
      'setAutomaticResourceManagementEnabled is not supported by '
      'firebase_core_tizen. Reason: firebase_dart does not expose a knob for '
      'automatic resource management on the underlying runtime.',
    );
  }

  /// Test hook: lets unit tests construct delegates without going through the
  /// runtime registry.
  @visibleForTesting
  static FirebaseAppTizen debugCreate({
    required String name,
    required FirebaseOptions options,
  }) {
    return FirebaseAppTizen(name: name, options: options);
  }
}
