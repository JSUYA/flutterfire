// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Tizen implementation of the `firebase_auth` plugin.
///
/// Application code must continue to import `package:firebase_auth/`; this
/// library only exists to register [FirebaseAuthTizen] as the platform
/// interface instance via the `dartPluginClass` entry in `pubspec.yaml`.
library firebase_auth_tizen;

export 'src/firebase_auth_tizen_impl.dart'
    show FirebaseAuthTizen, MultiFactorTizen;
export 'src/user_tizen.dart' show UserTizen;
