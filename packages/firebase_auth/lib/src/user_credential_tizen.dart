// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';

/// Concrete [UserCredentialPlatform] for Tizen.
///
/// The upstream `UserCredentialPlatform` constructor is abstract and cannot
/// be instantiated directly. We subclass it with a thin wrapper that holds
/// the mapped `AdditionalUserInfo` / `UserPlatform` so sign-in result
/// wiring stays clean.
class UserCredentialTizen extends UserCredentialPlatform {
  /// Creates a sign-in result for [auth] carrying the mapped delegate
  /// [user], credential-source metadata, and provider [credential].
  UserCredentialTizen({
    required FirebaseAuthPlatform auth,
    AdditionalUserInfo? additionalUserInfo,
    AuthCredential? credential,
    UserPlatform? user,
  }) : super(
          auth: auth,
          additionalUserInfo: additionalUserInfo,
          credential: credential,
          user: user,
        );
}
