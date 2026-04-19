// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Tizen implementation of the `firebase_core` plugin.
///
/// This library is what the Flutter plugin tool wires into
/// `GeneratedPluginRegistrant.register()` on Tizen through the
/// `dartPluginClass: FirebaseCoreTizen` declaration in `pubspec.yaml`.
///
/// Application code must continue to import `package:firebase_core/`: the
/// Tizen runtime surface exposed here is [`@internal`] and only for the use of
/// sibling `*_tizen` plugins (auth, database, storage, functions, …).
library firebase_core_tizen;

export 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart'
    show FirebaseException, FirebaseOptions, defaultFirebaseAppName;

export 'src/firebase_app_tizen.dart' show FirebaseAppTizen;
export 'src/firebase_core_tizen_impl.dart' show FirebaseCoreTizen;
export 'src/firebase_dart_conversions.dart'
    show FirebaseDartOptionsConversions;
export 'src/firebase_tizen_runtime.dart' show FirebaseTizenRuntime;
export 'src/tizen_auth_context.dart'
    show TizenAuthContext, TizenIdTokenProvider;
export 'src/tizen_http_client.dart'
    show TizenFirebaseHttpException, TizenHttpClient;
