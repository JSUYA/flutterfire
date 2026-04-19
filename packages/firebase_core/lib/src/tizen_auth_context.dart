// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:synchronized/synchronized.dart';

/// Signature of a callback that mints or refreshes a Firebase ID token.
typedef TizenIdTokenProvider = Future<String?> Function({
  required bool forceRefresh,
});

/// Brokers the currently-signed-in user's Firebase ID token so that sibling
/// Firebase Tizen plugins never run their own refresh timers.
///
/// There is exactly one instance per process, addressed per Firebase app
/// name. Plugins register a token provider (typically
/// `firebase_auth_tizen`) via [registerProvider], and callers read the
/// current token via [getIdToken] or subscribe to [idTokenChanges].
///
/// The token cache uses a [Lock] so that concurrent HTTP calls that all
/// refresh on a 401 trigger exactly one upstream refresh (singleflight).
///
/// This class is part of the *internal* Tizen-plugin surface (re-exported
/// from `firebase_core_tizen` for sibling plugins); application code must
/// continue to use `firebase_auth` for auth state.
class TizenAuthContext {
  TizenAuthContext._();

  /// Singleton accessor.
  static final TizenAuthContext instance = TizenAuthContext._();

  final Map<String, _AppAuthState> _perApp = <String, _AppAuthState>{};

  _AppAuthState _stateFor(String appName) {
    return _perApp.putIfAbsent(appName, _AppAuthState.new);
  }

  /// Registers the [provider] used to mint / refresh ID tokens for [appName].
  ///
  /// Calling this more than once for the same app replaces the previous
  /// provider — the typical lifecycle is one call from
  /// `FirebaseAuthTizen.register`.
  void registerProvider(String appName, TizenIdTokenProvider provider) {
    _stateFor(appName).provider = provider;
  }

  /// Removes any registered provider for [appName], emitting `null` on
  /// [idTokenChanges] if the cached token was cleared.
  void unregisterProvider(String appName) {
    final _AppAuthState? state = _perApp[appName];
    if (state == null) {
      return;
    }
    state.provider = null;
    state.pushToken(null);
  }

  /// Returns the current ID token for [appName], optionally forcing a
  /// refresh.
  ///
  /// Concurrent callers see the same refresh — subsequent calls block on the
  /// state's [Lock] and observe the fresh token when it is written.
  Future<String?> getIdToken(
    String appName, {
    bool forceRefresh = false,
  }) async {
    final _AppAuthState state = _stateFor(appName);
    if (!forceRefresh) {
      final String? cached = state.cachedToken;
      if (cached != null) {
        return cached;
      }
    }
    return state.lock.synchronized<String?>(() async {
      if (!forceRefresh) {
        final String? cached = state.cachedToken;
        if (cached != null) {
          return cached;
        }
      }
      final TizenIdTokenProvider? provider = state.provider;
      if (provider == null) {
        return null;
      }
      final String? token = await provider(forceRefresh: forceRefresh);
      state.pushToken(token);
      return token;
    });
  }

  /// Broadcast stream of ID token changes for [appName].
  Stream<String?> idTokenChanges(String appName) {
    return _stateFor(appName).controller.stream;
  }

  /// Pushes [token] into the cache without invoking the provider, used by the
  /// auth plugin to mirror its own `idTokenChanges` stream.
  void notifyToken(String appName, String? token) {
    _stateFor(appName).pushToken(token);
  }

  /// Clears the cached token and emits `null` on the stream.
  void clear(String appName) {
    _stateFor(appName).pushToken(null);
  }

  /// Test-only hook to drop every recorded app state.
  @visibleForTesting
  Future<void> resetForTesting() async {
    for (final _AppAuthState state in _perApp.values) {
      await state.controller.close();
    }
    _perApp.clear();
  }
}

class _AppAuthState {
  _AppAuthState();

  final Lock lock = Lock();
  final StreamController<String?> controller =
      StreamController<String?>.broadcast();

  String? cachedToken;
  TizenIdTokenProvider? provider;

  void pushToken(String? token) {
    cachedToken = token;
    controller.add(token);
  }
}
