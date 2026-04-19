// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_dart/firebase_dart.dart' as fd;

import 'auth_error_mapper.dart';

/// Tizen implementation of [UserPlatform].
///
/// Wraps a `firebase_dart.User` but never logs the token or stringifies it —
/// `toString` deliberately redacts every credential field that could leak
/// authentication material into a device log.
class UserTizen extends UserPlatform {
  /// Creates a delegate for [user] inside [auth].
  UserTizen(FirebaseAuthPlatform auth, MultiFactorPlatform multiFactor,
      this._user)
      : super(auth, multiFactor, _snapshotFromUser(_user));

  final fd.User _user;

  /// Convenience accessor for the wrapped firebase_dart user.
  fd.User get dartUser => _user;

  static Map<String, Object?> _snapshotFromUser(fd.User user) {
    return <String, Object?>{
      'uid': user.uid,
      'email': user.email,
      'emailVerified': user.emailVerified,
      'isAnonymous': user.isAnonymous,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'phoneNumber': user.phoneNumber,
      'refreshToken': null, // Intentionally omitted.
      'tenantId': user.tenantId,
      'providerData': user.providerData
          .map((fd.UserInfo info) => <String, Object?>{
                'uid': info.uid,
                'providerId': info.providerId,
                'displayName': info.displayName,
                'email': info.email,
                'photoURL': info.photoURL,
                'phoneNumber': info.phoneNumber,
              })
          .toList(growable: false),
      'metadata': <String, Object?>{
        'creationTime': user.metadata.creationTime?.millisecondsSinceEpoch,
        'lastSignInTime': user.metadata.lastSignInTime?.millisecondsSinceEpoch,
      },
    };
  }

  @override
  Future<void> delete() async {
    try {
      await _user.delete();
    } catch (error, stack) {
      throw AuthErrorMapper.map(error, stack);
    }
  }

  @override
  Future<String> getIdToken([bool forceRefresh = false]) async {
    try {
      final String? token = await _user.getIdToken(forceRefresh);
      if (token == null) {
        throw FirebaseAuthException(
          code: 'user-token-expired',
          message: 'firebase_dart returned a null ID token for the user.',
        );
      }
      return token;
    } catch (error, stack) {
      throw AuthErrorMapper.map(error, stack);
    }
  }

  @override
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) async {
    // TODO(parity): rewrite against PigeonIdTokenResult once we verify
    // its exact shape against firebase_auth_platform_interface 8.1.9.
    // For now throw explicitly rather than construct an IdTokenResult
    // with values that may not satisfy the upstream constructor.
    throw UnimplementedError(
      'getIdTokenResult is not yet supported by firebase_auth_tizen. '
      'Reason: firebase_auth_platform_interface 8.1.9 changed IdTokenResult '
      'to accept a PigeonIdTokenResult; the Tizen implementation needs to '
      'build that object instead of a raw Map. Tracked as a known parity '
      'gap — use getIdToken() for the bearer token.',
    );
  }

  @override
  Future<void> reload() async {
    try {
      await _user.reload();
    } catch (error, stack) {
      throw AuthErrorMapper.map(error, stack);
    }
  }

  @override
  Future<void> sendEmailVerification(
      [ActionCodeSettings? actionCodeSettings]) async {
    try {
      await _user.sendEmailVerification();
    } catch (error, stack) {
      throw AuthErrorMapper.map(error, stack);
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      await _user.updatePassword(newPassword);
    } catch (error, stack) {
      throw AuthErrorMapper.map(error, stack);
    }
  }

  @override
  Future<void> verifyBeforeUpdateEmail(
    String newEmail, [
    ActionCodeSettings? actionCodeSettings,
  ]) async {
    try {
      await _user.verifyBeforeUpdateEmail(newEmail);
    } catch (error, stack) {
      throw AuthErrorMapper.map(error, stack);
    }
  }

  @override
  Future<void> updateProfile(Map<String, String?> profile) async {
    try {
      await _user.updateProfile(
        displayName: profile['displayName'],
        photoURL: profile['photoURL'],
      );
      await _user.reload();
    } catch (error, stack) {
      throw AuthErrorMapper.map(error, stack);
    }
  }

  @override
  Future<UserPlatform> unlink(String providerId) {
    throw UnimplementedError(
      'unlink is not supported by firebase_auth_tizen. Reason: OAuth provider '
      'flows are not available on Tizen (no reCAPTCHA / redirect handler).',
    );
  }

  @override
  Future<UserCredentialPlatform> linkWithCredential(
      AuthCredential credential) {
    throw UnimplementedError(
      'linkWithCredential is not supported by firebase_auth_tizen. Reason: '
      'only email/password and anonymous credentials are linkable today; '
      'OAuth providers require a redirect handler that Tizen TV apps lack.',
    );
  }

  @override
  Future<UserCredentialPlatform> reauthenticateWithCredential(
      AuthCredential credential) {
    throw UnimplementedError(
      'reauthenticateWithCredential is not supported by firebase_auth_tizen. '
      'Reason: unresolved firebase_dart issue around OAuth reauth; use '
      'signInWithCustomToken instead.',
    );
  }

  @override
  Future<UserPlatform> updatePhoneNumber(PhoneAuthCredential credential) {
    throw UnimplementedError(
      'updatePhoneNumber is not supported by firebase_auth_tizen. Reason: '
      'phone auth (reCAPTCHA + SMS retrieval) is unavailable on Tizen.',
    );
  }

  @override
  String toString() =>
      'UserTizen(uid: ${_user.uid}, email: ${_user.email}, isAnonymous: '
      '${_user.isAnonymous})';
}
