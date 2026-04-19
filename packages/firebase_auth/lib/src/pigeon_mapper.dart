// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: implementation_imports
// firebase_auth_platform_interface 8.1.9 exposes its pigeon-generated
// message types under `src/pigeon/messages.pigeon.dart`, which is a
// package-private import. The Tizen implementation has to construct those
// typed data holders directly to satisfy UserPlatform/UserCredentialPlatform
// contracts, so we intentionally import the private path.

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_auth_platform_interface/src/pigeon/messages.pigeon.dart';
import 'package:firebase_dart/firebase_dart.dart' as fd;

/// Maps `firebase_dart` user / credential data onto the pigeon-generated
/// DTOs that `firebase_auth_platform_interface 8.1.9` expects.
class AuthPigeonMapper {
  /// Build a [PigeonUserInfo] for the primary account snapshot.
  static PigeonUserInfo userInfoFromDart(fd.User user) {
    return PigeonUserInfo(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      phoneNumber: user.phoneNumber,
      isAnonymous: user.isAnonymous,
      isEmailVerified: user.emailVerified,
      providerId: 'firebase',
      tenantId: user.tenantId,
      // Refresh tokens are held in the firebase_dart user object but are
      // deliberately not forwarded to the pigeon snapshot to keep the
      // token off log surfaces. Callers that need it use getIdToken().
      refreshToken: null,
      creationTimestamp: user.metadata.creationTime?.millisecondsSinceEpoch,
      lastSignInTimestamp: user.metadata.lastSignInTime?.millisecondsSinceEpoch,
    );
  }

  /// Each element of [PigeonUserDetails.providerData] is a JSON-style map
  /// (not a `PigeonUserInfo`) that the upstream `UserInfo.fromJson` parses.
  static List<Map<Object?, Object?>?> providerDataFromDart(fd.User user) {
    return user.providerData
        .map((fd.UserInfo info) => <Object?, Object?>{
              'uid': info.uid,
              'email': info.email,
              'displayName': info.displayName,
              'photoUrl': info.photoURL,
              'phoneNumber': info.phoneNumber,
              'isAnonymous': false,
              'isEmailVerified': false,
              'providerId': info.providerId,
              'tenantId': null,
              'refreshToken': null,
              'creationTimestamp': null,
              'lastSignInTimestamp': null,
            })
        .toList(growable: false);
  }

  /// Compose the full [PigeonUserDetails] the upstream `UserPlatform`
  /// constructor requires.
  static PigeonUserDetails detailsFromDart(fd.User user) {
    return PigeonUserDetails(
      userInfo: userInfoFromDart(user),
      providerData: providerDataFromDart(user),
    );
  }

  /// Build a [PigeonIdTokenResult] from the firebase_dart token result.
  static PigeonIdTokenResult idTokenResultFromDart(
    fd.IdTokenResult result,
    String token,
  ) {
    return PigeonIdTokenResult(
      token: token,
      expirationTimestamp: result.expirationTime?.millisecondsSinceEpoch,
      authTimestamp: result.authTime?.millisecondsSinceEpoch,
      issuedAtTimestamp: result.issuedAtTime?.millisecondsSinceEpoch,
      signInProvider: result.signInProvider,
      claims: _coerceClaims(result.claims),
      signInSecondFactor: null,
    );
  }

  /// Build an upstream [AdditionalUserInfo] from the firebase_dart credential.
  static AdditionalUserInfo? additionalUserInfoFromDart(
    fd.UserCredential credential,
  ) {
    final fd.AdditionalUserInfo? info = credential.additionalUserInfo;
    if (info == null) {
      return null;
    }
    return AdditionalUserInfo(
      isNewUser: info.isNewUser,
      providerId: info.providerId,
      username: info.username,
      profile: info.profile == null
          ? null
          : Map<String, dynamic>.from(info.profile!),
    );
  }

  /// Map firebase_dart's ActionCodeInfo onto the upstream wrapper.
  static ActionCodeInfo actionCodeInfoFromDart(fd.ActionCodeInfo info) {
    return ActionCodeInfo(
      operation: _mapActionOperation(info.operation),
      data: ActionCodeInfoData(
        email: info.data.email,
        previousEmail: info.data.previousEmail,
      ),
    );
  }

  static ActionCodeInfoOperation _mapActionOperation(
    fd.ActionCodeInfoOperation operation,
  ) {
    // firebase_dart exposes the same logical cases; map by name so a
    // future upstream reordering does not silently misclassify.
    switch (operation.name) {
      case 'passwordReset':
        return ActionCodeInfoOperation.passwordReset;
      case 'verifyEmail':
        return ActionCodeInfoOperation.verifyEmail;
      case 'recoverEmail':
        return ActionCodeInfoOperation.recoverEmail;
      case 'emailSignIn':
      case 'signInWithEmailLink':
        return ActionCodeInfoOperation.emailSignIn;
      case 'verifyAndChangeEmail':
        return ActionCodeInfoOperation.verifyAndChangeEmail;
      case 'revertSecondFactorAddition':
        return ActionCodeInfoOperation.revertSecondFactorAddition;
      default:
        return ActionCodeInfoOperation.unknown;
    }
  }

  static Map<String?, Object?>? _coerceClaims(Map<String, Object?>? claims) {
    if (claims == null) {
      return null;
    }
    return <String?, Object?>{
      for (final MapEntry<String, Object?> entry in claims.entries)
        entry.key: entry.value,
    };
  }
}
