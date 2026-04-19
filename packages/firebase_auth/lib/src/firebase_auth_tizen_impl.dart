// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_tizen/firebase_core_tizen.dart';
import 'package:firebase_dart/firebase_dart.dart' as fd;
import 'package:meta/meta.dart';

import 'auth_error_mapper.dart';
import 'pigeon_mapper.dart';
import 'user_credential_tizen.dart';
import 'user_tizen.dart';

/// Tizen implementation of [FirebaseAuthPlatform].
///
/// Registered via the `dartPluginClass: FirebaseAuthTizen` entry in
/// `pubspec.yaml`, which causes the flutter-tizen plugin tool to wire
/// `FirebaseAuthTizen.register()` into `GeneratedPluginRegistrant`.
class FirebaseAuthTizen extends FirebaseAuthPlatform {
  /// Internal constructor; app code obtains instances through the
  /// `firebase_auth` public API.
  @visibleForTesting
  FirebaseAuthTizen.private({
    required FirebaseApp app,
  }) : super(appInstance: app) {
    _wireTokenBridge();
  }

  FirebaseAuthTizen._() : super(appInstance: null);

  /// Entry point used by `GeneratedPluginRegistrant.register` on Tizen.
  static void register() {
    FirebaseAuthPlatform.instance = FirebaseAuthTizen._();
  }

  fd.FirebaseAuth get _dartAuth => fd.FirebaseAuth.instanceFor(
        app: FirebaseTizenRuntime.instance.dartAppFor(
          app?.name ?? defaultFirebaseAppName,
        ),
      );

  StreamSubscription<fd.User?>? _tokenBridge;

  void _wireTokenBridge() {
    final String appName = app?.name ?? defaultFirebaseAppName;
    TizenAuthContext.instance.registerProvider(
      appName,
      ({required bool forceRefresh}) async {
        final fd.User? user = _dartAuth.currentUser;
        if (user == null) {
          return null;
        }
        try {
          return await user.getIdToken(forceRefresh);
        } catch (error, stack) {
          throw AuthErrorMapper.map(error, stack);
        }
      },
    );

    _tokenBridge?.cancel();
    _tokenBridge = _dartAuth.userChanges().listen((fd.User? user) async {
      if (user == null) {
        TizenAuthContext.instance.notifyToken(appName, null);
      } else {
        try {
          final String? token = await user.getIdToken();
          TizenAuthContext.instance.notifyToken(appName, token);
        } catch (_) {
          TizenAuthContext.instance.notifyToken(appName, null);
        }
      }
    });
  }

  @override
  FirebaseAuthPlatform delegateFor({required FirebaseApp app}) {
    return FirebaseAuthTizen.private(app: app);
  }

  @override
  FirebaseAuthPlatform setInitialValues({
    PigeonUserDetails? currentUser,
    String? languageCode,
  }) {
    return this;
  }

  @override
  UserPlatform? get currentUser {
    final fd.User? user = _dartAuth.currentUser;
    if (user == null) {
      return null;
    }
    return UserTizen(this, MultiFactorTizen(this), user);
  }

  @override
  Stream<UserPlatform?> authStateChanges() {
    return _dartAuth.authStateChanges().map(_wrapUser);
  }

  @override
  Stream<UserPlatform?> idTokenChanges() {
    return _dartAuth.idTokenChanges().map(_wrapUser);
  }

  @override
  Stream<UserPlatform?> userChanges() {
    return _dartAuth.userChanges().map(_wrapUser);
  }

  UserPlatform? _wrapUser(fd.User? user) {
    if (user == null) {
      return null;
    }
    return UserTizen(this, MultiFactorTizen(this), user);
  }

  @override
  Future<UserCredentialPlatform> signInAnonymously() async {
    return _runSignIn(() => _dartAuth.signInAnonymously());
  }

  @override
  Future<UserCredentialPlatform> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return _runSignIn(() =>
        _dartAuth.signInWithEmailAndPassword(email: email, password: password));
  }

  @override
  Future<UserCredentialPlatform> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return _runSignIn(() => _dartAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        ));
  }

  @override
  Future<UserCredentialPlatform> signInWithCustomToken(String token) async {
    return _runSignIn(() => _dartAuth.signInWithCustomToken(token));
  }

  @override
  Future<UserCredentialPlatform> signInWithCredential(
      AuthCredential credential) async {
    if (credential is EmailAuthCredential) {
      final String? email = credential.email;
      final String? password = credential.password;
      if (email != null && password != null) {
        return signInWithEmailAndPassword(email, password);
      }
    }
    throw UnimplementedError(
      'signInWithCredential is supported only for email/password credentials '
      'on Tizen. Use signInWithCustomToken minted from your backend for OAuth.',
    );
  }

  @override
  Future<UserCredentialPlatform> signInWithEmailLink(
    String email,
    String emailLink,
  ) async {
    throw UnimplementedError(
      'signInWithEmailLink is not supported by firebase_auth_tizen. Reason: '
      'link interception requires a redirect handler that TV apps do not '
      'ship.',
    );
  }

  @override
  Future<void> sendPasswordResetEmail(
    String email, [
    ActionCodeSettings? actionCodeSettings,
  ]) async {
    try {
      await _dartAuth.sendPasswordResetEmail(email: email);
    } catch (error, stack) {
      throw AuthErrorMapper.map(error, stack);
    }
  }

  @override
  Future<void> confirmPasswordReset(String code, String newPassword) async {
    try {
      await _dartAuth.confirmPasswordReset(code, newPassword);
    } catch (error, stack) {
      throw AuthErrorMapper.map(error, stack);
    }
  }

  @override
  Future<String> verifyPasswordResetCode(String code) async {
    try {
      return await _dartAuth.verifyPasswordResetCode(code);
    } catch (error, stack) {
      throw AuthErrorMapper.map(error, stack);
    }
  }

  @override
  Future<void> applyActionCode(String code) async {
    try {
      await _dartAuth.applyActionCode(code);
    } catch (error, stack) {
      throw AuthErrorMapper.map(error, stack);
    }
  }

  @override
  Future<ActionCodeInfo> checkActionCode(String code) async {
    try {
      final fd.ActionCodeInfo info = await _dartAuth.checkActionCode(code);
      return AuthPigeonMapper.actionCodeInfoFromDart(info);
    } catch (error, stack) {
      throw AuthErrorMapper.map(error, stack);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _dartAuth.signOut();
    } catch (error, stack) {
      throw AuthErrorMapper.map(error, stack);
    }
  }

  @override
  Future<void> setLanguageCode(String? languageCode) async {
    // firebase_dart's setLanguageCode requires a non-null String. Guard
    // null so we don't crash on Dart's implicit cast.
    if (languageCode == null) {
      return;
    }
    _dartAuth.setLanguageCode(languageCode);
  }

  @override
  String? get languageCode => _dartAuth.languageCode;

  @override
  Future<void> useAuthEmulator(String host, int port) {
    throw UnimplementedError(
      'useAuthEmulator is not supported by firebase_auth_tizen. Reason: the '
      'Auth emulator relies on local loopback certificates that TV devices '
      'do not trust.',
    );
  }

  @override
  Future<void> verifyPhoneNumber({
    String? phoneNumber,
    PhoneMultiFactorInfo? multiFactorInfo,
    required PhoneVerificationCompleted verificationCompleted,
    required PhoneVerificationFailed verificationFailed,
    required PhoneCodeSent codeSent,
    required PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
    String? autoRetrievedSmsCodeForTesting,
    Duration timeout = const Duration(seconds: 30),
    int? forceResendingToken,
    MultiFactorSession? multiFactorSession,
  }) {
    throw UnimplementedError(
      'verifyPhoneNumber is not supported by firebase_auth_tizen. Reason: '
      'Tizen has no SMS retrieval API and no reCAPTCHA verifier.',
    );
  }

  @override
  Future<void> setPersistence(Persistence persistence) {
    throw UnimplementedError(
      'setPersistence is not supported by firebase_auth_tizen. Reason: '
      'persistence is fixed to the firebase_dart Hive box owned by '
      'firebase_core_tizen.',
    );
  }

  Future<UserCredentialPlatform> _runSignIn(
    Future<fd.UserCredential> Function() body,
  ) async {
    try {
      final fd.UserCredential credential = await body();
      return _wrapCredential(credential);
    } catch (error, stack) {
      throw AuthErrorMapper.map(error, stack);
    }
  }

  UserCredentialPlatform _wrapCredential(fd.UserCredential credential) {
    final fd.User? user = credential.user;
    final UserTizen? wrapped =
        user == null ? null : UserTizen(this, MultiFactorTizen(this), user);
    return UserCredentialTizen(
      auth: this,
      additionalUserInfo: AuthPigeonMapper.additionalUserInfoFromDart(credential),
      credential: null,
      user: wrapped,
    );
  }
}

/// Tizen stub for [MultiFactorPlatform].
///
/// Multi-factor flows depend on phone / TOTP / WebAuthn integrations that are
/// not available on Tizen, so every method throws `UnimplementedError`.
class MultiFactorTizen extends MultiFactorPlatform {
  /// Constructs a stub associated with [auth].
  MultiFactorTizen(FirebaseAuthTizen super.auth);

  @override
  Future<void> enroll(
    MultiFactorAssertionPlatform assertion, {
    String? displayName,
  }) {
    throw UnimplementedError(
      'MultiFactor.enroll is not supported by firebase_auth_tizen.',
    );
  }

  @override
  Future<void> unenroll({
    String? factorUid,
    MultiFactorInfo? multiFactorInfo,
  }) {
    throw UnimplementedError(
      'MultiFactor.unenroll is not supported by firebase_auth_tizen.',
    );
  }

  @override
  Future<List<MultiFactorInfo>> getEnrolledFactors() async {
    return const <MultiFactorInfo>[];
  }

  @override
  Future<MultiFactorSession> getSession() {
    throw UnimplementedError(
      'MultiFactor.getSession is not supported by firebase_auth_tizen.',
    );
  }
}
