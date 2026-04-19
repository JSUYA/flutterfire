// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_database_platform_interface/firebase_database_platform_interface.dart';
import 'package:firebase_dart/firebase_dart.dart' as fd;

/// Tizen [OnDisconnectPlatform] delegate.
///
/// `firebase_dart` exposes the OnDisconnect primitives on the Realtime
/// Database reference; the delegate forwards each call.
class OnDisconnectTizen extends OnDisconnectPlatform {
  /// Wraps a `firebase_dart` onDisconnect handle for [reference].
  OnDisconnectTizen(
    DatabaseReferencePlatform reference,
    this._reference,
  ) : super(reference: reference);

  final fd.DatabaseReference _reference;

  @override
  Future<void> set(Object? value) {
    return _reference.onDisconnect().set(value);
  }

  @override
  Future<void> setWithPriority(Object? value, Object? priority) {
    return _reference.onDisconnect().setWithPriority(value, priority);
  }

  @override
  Future<void> remove() {
    return _reference.onDisconnect().remove();
  }

  @override
  Future<void> cancel() {
    return _reference.onDisconnect().cancel();
  }

  @override
  Future<void> update(Map<String, Object?> value) {
    return _reference.onDisconnect().update(value);
  }
}
