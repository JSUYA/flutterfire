// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_dart/firebase_dart.dart' as fd;

import 'auth_error_mapper.dart';
import 'pigeon_mapper.dart';

/// Tizen implementation of [UserPlatform].
///
/// Wraps a `firebase_dart.User` and surfaces the snapshot through the
/// pigeon-generated `PigeonUserDetails` type the upstream platform
/// interface requires. `toString` deliberately omits the refresh token so
/// debug logs cannot leak auth material.
class UserTizen extends UserPlatform {
  /// Creates a delegate for [user] inside [auth].
  UserTizen(
    FirebaseAuthPlatform auth,
    MultiFactorPlatform multiFactor,
    this._user,
  ) : super(auth, multiFactor, AuthPigeonMapper.detailsFromDart(_user));

  final fd.User _user;

  /// Convenience accessor for the wrapped firebase_dart user.
  fd.User get dartUser => _user;

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
    try {
      final String token = await getIdToken(forceRefresh);
      final fd.IdTokenResult result =
          await _user.getIdTokenResult(forceRefresh);
      return IdTokenResult(
        AuthPigeonMapper.idTokenResultFromDart(result, token),
      );
    } catch (error, stack) {
      throw AuthErrorMapper.map(error, stack);
    }
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
