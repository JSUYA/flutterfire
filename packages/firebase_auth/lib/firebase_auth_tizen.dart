import 'dart:async';

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_tizen/firebase_core_tizen.dart'
    show FirebaseTizenRuntime;
import 'package:firebase_dart/auth.dart' as firebase_dart;

/// Tizen implementation of [FirebaseAuthPlatform].
class FirebaseAuthTizen extends FirebaseAuthPlatform {
  /// Creates a Firebase Auth platform instance for Tizen.
  FirebaseAuthTizen({super.appInstance});

  /// Registers this implementation as the default auth platform.
  static void register() {
    FirebaseAuthPlatform.instance = FirebaseAuthTizen();
  }

  String? _languageCode;
  UserPlatform? _currentUserOverride;

  firebase_dart.FirebaseAuth _auth() {
    final FirebaseApp app = appInstance ?? Firebase.app();
    return firebase_dart.FirebaseAuth.instanceFor(
      app: FirebaseTizenRuntime.dartAppForPublicApp(app),
    )..tenantId = tenantId;
  }

  @override
  FirebaseAuthPlatform delegateFor({required FirebaseApp app}) {
    return FirebaseAuthTizen(appInstance: app)
      ..tenantId = tenantId
      ..customAuthDomain = customAuthDomain
      .._languageCode = _languageCode;
  }

  @override
  FirebaseAuthPlatform setInitialValues({
    PigeonUserDetails? currentUser,
    String? languageCode,
  }) {
    _languageCode = languageCode;
    _currentUserOverride = currentUser == null
        ? null
        : _UserTizen(auth: this, user: null, details: currentUser);
    return this;
  }

  @override
  UserPlatform? get currentUser {
    if (!FirebaseTizenRuntime.isConfigured) {
      return _currentUserOverride;
    }

    final firebase_dart.User? user = _auth().currentUser;
    if (user == null) {
      return null;
    }
    return _UserTizen(auth: this, user: user);
  }

  @override
  set currentUser(UserPlatform? userPlatform) {
    _currentUserOverride = userPlatform;
  }

  @override
  String? get languageCode => _languageCode;

  @override
  Stream<UserPlatform?> authStateChanges() async* {
    await FirebaseTizenRuntime.ensureInitialized();
    yield* _auth().authStateChanges().map<UserPlatform?>(
          (firebase_dart.User? user) =>
              user == null ? null : _UserTizen(auth: this, user: user),
        );
  }

  @override
  Stream<UserPlatform?> idTokenChanges() async* {
    await FirebaseTizenRuntime.ensureInitialized();
    yield* _auth().idTokenChanges().map<UserPlatform?>(
          (firebase_dart.User? user) =>
              user == null ? null : _UserTizen(auth: this, user: user),
        );
  }

  @override
  Stream<UserPlatform?> userChanges() async* {
    await FirebaseTizenRuntime.ensureInitialized();
    yield* _auth().userChanges().map<UserPlatform?>(
          (firebase_dart.User? user) =>
              user == null ? null : _UserTizen(auth: this, user: user),
        );
  }

  @override
  void sendAuthChangesEvent(String appName, UserPlatform? userPlatform) {}

  @override
  Future<void> applyActionCode(String code) async {
    await FirebaseTizenRuntime.ensureInitialized();
    await _runAuthOperation(() => _auth().applyActionCode(code));
  }

  @override
  Future<ActionCodeInfo> checkActionCode(String code) async {
    await FirebaseTizenRuntime.ensureInitialized();
    final firebase_dart.ActionCodeInfo info = await _runAuthOperation(
      () => _auth().checkActionCode(code),
    );
    return ActionCodeInfo(
      operation: _mapActionCodeOperation(info.operation),
      data: ActionCodeInfoData(
        email: info.data['email'] as String?,
        previousEmail: info.data['previousEmail'] as String?,
      ),
    );
  }

  @override
  Future<void> confirmPasswordReset(String code, String newPassword) async {
    await FirebaseTizenRuntime.ensureInitialized();
    await _runAuthOperation(
      () => _auth().confirmPasswordReset(code, newPassword),
    );
  }

  @override
  Future<UserCredentialPlatform> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    await FirebaseTizenRuntime.ensureInitialized();
    final firebase_dart.UserCredential credential = await _runAuthOperation(
      () => _auth().createUserWithEmailAndPassword(
        email: email,
        password: password,
      ),
    );
    return _toUserCredential(credential);
  }

  @override
  Future<List<String>> fetchSignInMethodsForEmail(String email) async {
    await FirebaseTizenRuntime.ensureInitialized();
    return _runAuthOperation(() => _auth().fetchSignInMethodsForEmail(email));
  }

  @override
  Future<UserCredentialPlatform> getRedirectResult() async {
    throw UnimplementedError(
      'Redirect-based sign-in is not supported on Tizen.',
    );
  }

  @override
  Future<void> sendPasswordResetEmail(
    String email, [
    ActionCodeSettings? actionCodeSettings,
  ]) async {
    await FirebaseTizenRuntime.ensureInitialized();
    await _runAuthOperation(
      () => _auth().sendPasswordResetEmail(
        email: email,
        actionCodeSettings: _toDartActionCodeSettings(actionCodeSettings),
      ),
    );
  }

  @override
  Future<void> sendSignInLinkToEmail(
    String email,
    ActionCodeSettings actionCodeSettings,
  ) async {
    await FirebaseTizenRuntime.ensureInitialized();
    await _runAuthOperation(
      () => _auth().sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: _toDartActionCodeSettings(actionCodeSettings)!,
      ),
    );
  }

  @override
  Future<void> setLanguageCode(String? languageCode) async {
    _languageCode = languageCode;
  }

  @override
  Future<void> setPersistence(Persistence persistence) async {
    throw UnimplementedError(
      'Changing auth persistence is not supported on Tizen.',
    );
  }

  @override
  Future<void> setSettings({
    bool appVerificationDisabledForTesting = false,
    String? userAccessGroup,
    String? phoneNumber,
    String? smsCode,
    bool? forceRecaptchaFlow,
  }) async {
    if (appVerificationDisabledForTesting ||
        (forceRecaptchaFlow ?? false) ||
        userAccessGroup != null ||
        phoneNumber != null ||
        smsCode != null) {
      throw UnimplementedError(
        'Auth testing and shared keychain settings are not supported on Tizen.',
      );
    }
  }

  @override
  Future<UserCredentialPlatform> signInAnonymously() async {
    await FirebaseTizenRuntime.ensureInitialized();
    return _toUserCredential(
      await _runAuthOperation(_auth().signInAnonymously),
    );
  }

  @override
  Future<UserCredentialPlatform> signInWithProvider(
    AuthProvider provider,
  ) async {
    throw UnimplementedError(
      'Provider-driven sign-in flows are not supported on Tizen.',
    );
  }

  @override
  Future<UserCredentialPlatform> signInWithCredential(
    AuthCredential credential,
  ) async {
    await FirebaseTizenRuntime.ensureInitialized();
    final firebase_dart.UserCredential result = await _runAuthOperation(
      () => _auth().signInWithCredential(_toDartCredential(credential)),
    );
    return _toUserCredential(result);
  }

  @override
  Future<UserCredentialPlatform> signInWithCustomToken(String token) async {
    await FirebaseTizenRuntime.ensureInitialized();
    return _toUserCredential(
      await _runAuthOperation(() => _auth().signInWithCustomToken(token)),
    );
  }

  @override
  Future<UserCredentialPlatform> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    await FirebaseTizenRuntime.ensureInitialized();
    return _toUserCredential(
      await _runAuthOperation(
        () => _auth().signInWithEmailAndPassword(
          email: email,
          password: password,
        ),
      ),
    );
  }

  @override
  Future<UserCredentialPlatform> signInWithEmailLink(
    String email,
    String emailLink,
  ) async {
    await FirebaseTizenRuntime.ensureInitialized();
    return _toUserCredential(
      await _runAuthOperation(
        () => _auth().signInWithEmailLink(email: email, emailLink: emailLink),
      ),
    );
  }

  @override
  Future<UserCredentialPlatform> signInWithPopup(AuthProvider provider) async {
    throw UnimplementedError('Popup-based sign-in is not supported on Tizen.');
  }

  @override
  Future<void> signInWithRedirect(AuthProvider provider) async {
    throw UnimplementedError(
      'Redirect-based sign-in is not supported on Tizen.',
    );
  }

  @override
  Future<void> signOut() async {
    await FirebaseTizenRuntime.ensureInitialized();
    await _runAuthOperation(_auth().signOut);
  }

  @override
  Future<void> useAuthEmulator(String host, int port) async {
    throw UnimplementedError(
      'Firebase Auth emulator is not supported on Tizen.',
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
  }) async {
    throw UnimplementedError(
      'Phone number verification is not supported on Tizen.',
    );
  }

  firebase_dart.ActionCodeSettings? _toDartActionCodeSettings(
    ActionCodeSettings? settings,
  ) {
    if (settings == null) {
      return null;
    }
    return firebase_dart.ActionCodeSettings(
      url: settings.url,
      dynamicLinkDomain: settings.linkDomain,
      handleCodeInApp: settings.handleCodeInApp,
      iOSBundleId: settings.iOSBundleId,
      androidPackageName: settings.androidPackageName,
      androidInstallApp: settings.androidInstallApp,
      androidMinimumVersion: settings.androidMinimumVersion,
    );
  }

  firebase_dart.AuthCredential _toDartCredential(AuthCredential credential) {
    if (credential is EmailAuthCredential) {
      if (credential.emailLink != null) {
        return firebase_dart.EmailAuthProvider.credentialWithLink(
          email: credential.email,
          emailLink: credential.emailLink!,
        );
      }
      return firebase_dart.EmailAuthProvider.credential(
        email: credential.email,
        password: credential.password!,
      );
    }

    if (credential is PhoneAuthCredential) {
      return firebase_dart.PhoneAuthProvider.credential(
        verificationId: credential.verificationId!,
        smsCode: credential.smsCode!,
      );
    }

    if (credential is OAuthCredential) {
      return firebase_dart.OAuthProvider.credential(
        providerId: credential.providerId,
        accessToken: credential.accessToken,
        idToken: credential.idToken,
        rawNonce: credential.rawNonce,
      );
    }

    throw UnimplementedError(
      'Unsupported auth credential: ${credential.runtimeType}.',
    );
  }

  AuthCredential? _fromDartCredential(
    firebase_dart.AuthCredential? credential,
  ) {
    if (credential == null) {
      return null;
    }
    if (credential is firebase_dart.EmailAuthCredential) {
      if (credential.emailLink != null) {
        return EmailAuthProvider.credentialWithLink(
          email: credential.email,
          emailLink: credential.emailLink!,
        );
      }
      return EmailAuthProvider.credential(
        email: credential.email,
        password: credential.password!,
      );
    }
    if (credential is firebase_dart.PhoneAuthCredential) {
      return PhoneAuthProvider.credential(
        verificationId: credential.verificationId!,
        smsCode: credential.smsCode!,
      );
    }
    if (credential is firebase_dart.OAuthCredential) {
      return OAuthProvider(credential.providerId).credential(
        accessToken: credential.accessToken,
        idToken: credential.idToken,
        rawNonce: credential.rawNonce,
        signInMethod: credential.signInMethod,
      );
    }

    return AuthCredential(
      providerId: credential.providerId,
      signInMethod: credential.signInMethod,
    );
  }

  AdditionalUserInfo? _toAdditionalUserInfo(
    firebase_dart.AdditionalUserInfo? info,
  ) {
    if (info == null) {
      return null;
    }
    return AdditionalUserInfo(
      isNewUser: info.isNewUser,
      profile: info.profile,
      providerId: info.providerId,
      username: info.username,
    );
  }

  ActionCodeInfoOperation _mapActionCodeOperation(
    firebase_dart.ActionCodeInfoOperation operation,
  ) {
    switch (operation) {
      case firebase_dart.ActionCodeInfoOperation.passwordReset:
        return ActionCodeInfoOperation.passwordReset;
      case firebase_dart.ActionCodeInfoOperation.verifyEmail:
        return ActionCodeInfoOperation.verifyEmail;
      case firebase_dart.ActionCodeInfoOperation.recoverEmail:
        return ActionCodeInfoOperation.recoverEmail;
      case firebase_dart.ActionCodeInfoOperation.emailSignIn:
        return ActionCodeInfoOperation.emailSignIn;
      case firebase_dart.ActionCodeInfoOperation.verifyAndChangeEmail:
        return ActionCodeInfoOperation.verifyAndChangeEmail;
      case firebase_dart.ActionCodeInfoOperation.revertSecondFactorAddition:
        return ActionCodeInfoOperation.revertSecondFactorAddition;
      case firebase_dart.ActionCodeInfoOperation.unknown:
        return ActionCodeInfoOperation.unknown;
    }
  }

  UserCredentialPlatform _toUserCredential(
    firebase_dart.UserCredential credential,
  ) {
    final firebase_dart.User? user = credential.user;
    return _UserCredentialTizen(
      auth: this,
      additionalUserInfo: _toAdditionalUserInfo(credential.additionalUserInfo),
      credential: _fromDartCredential(credential.credential),
      user: user == null ? null : _UserTizen(auth: this, user: user),
    );
  }

  PigeonUserDetails _toPigeonUserDetails(firebase_dart.User user) {
    final String? providerId =
        user.providerData.isEmpty ? null : user.providerData.first.providerId;
    return PigeonUserDetails(
      userInfo: PigeonUserInfo(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoUrl: user.photoURL,
        phoneNumber: user.phoneNumber,
        isAnonymous: user.isAnonymous,
        isEmailVerified: user.emailVerified,
        providerId: providerId,
        tenantId: user.tenantId,
        refreshToken: user.refreshToken,
        creationTimestamp: user.metadata.creationTime?.millisecondsSinceEpoch,
        lastSignInTimestamp:
            user.metadata.lastSignInTime?.millisecondsSinceEpoch,
      ),
      providerData: user.providerData
          .map<Map<Object?, Object?>?>(
            (firebase_dart.UserInfo info) => info.toJson(),
          )
          .toList(growable: false),
    );
  }

  Future<T> _runAuthOperation<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on firebase_dart.FirebaseAuthException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        FirebaseAuthException(
          code: error.code,
          message: error.message,
          email: error.email,
          credential: _fromDartCredential(error.credential),
          phoneNumber: error.phoneNumber,
          tenantId: tenantId,
        ),
        stackTrace,
      );
    }
  }
}

class _UserTizen extends UserPlatform {
  _UserTizen({
    required FirebaseAuthTizen auth,
    required firebase_dart.User? user,
    PigeonUserDetails? details,
  })  : _auth = auth,
        _user = user,
        super(
          auth,
          _NoopMultiFactorPlatform(auth),
          details ?? auth._toPigeonUserDetails(user!),
        );

  final FirebaseAuthTizen _auth;
  final firebase_dart.User? _user;

  firebase_dart.User get _delegate {
    return _user ??
        _auth._auth().currentUser ??
        (throw FirebaseAuthException(
          code: 'no-current-user',
          message: 'No current Firebase Auth user is available.',
        ));
  }

  @override
  Future<void> delete() async {
    await FirebaseTizenRuntime.ensureInitialized();
    await _auth._runAuthOperation(_delegate.delete);
  }

  @override
  Future<String?> getIdToken(bool forceRefresh) async {
    await FirebaseTizenRuntime.ensureInitialized();
    return _auth._runAuthOperation(() => _delegate.getIdToken(forceRefresh));
  }

  @override
  Future<IdTokenResult> getIdTokenResult(bool forceRefresh) async {
    await FirebaseTizenRuntime.ensureInitialized();
    final firebase_dart.IdTokenResult result = await _auth._runAuthOperation(
      () => _delegate.getIdTokenResult(forceRefresh),
    );
    return IdTokenResult(
      PigeonIdTokenResult(
        token: result.token,
        expirationTimestamp: result.expirationTime?.millisecondsSinceEpoch,
        authTimestamp: result.authTime?.millisecondsSinceEpoch,
        issuedAtTimestamp: result.issuedAtTime?.millisecondsSinceEpoch,
        signInProvider: result.signInProvider,
        claims: result.claims,
        signInSecondFactor: result.signInSecondFactor,
      ),
    );
  }

  @override
  Future<UserCredentialPlatform> linkWithCredential(
    AuthCredential credential,
  ) async {
    await FirebaseTizenRuntime.ensureInitialized();
    return _auth._toUserCredential(
      await _auth._runAuthOperation(
        () => _delegate.linkWithCredential(_auth._toDartCredential(credential)),
      ),
    );
  }

  @override
  Future<void> reload() async {
    await FirebaseTizenRuntime.ensureInitialized();
    await _auth._runAuthOperation(_delegate.reload);
  }

  @override
  Future<UserCredentialPlatform> reauthenticateWithCredential(
    AuthCredential credential,
  ) async {
    await FirebaseTizenRuntime.ensureInitialized();
    return _auth._toUserCredential(
      await _auth._runAuthOperation(
        () => _delegate.reauthenticateWithCredential(
          _auth._toDartCredential(credential),
        ),
      ),
    );
  }

  @override
  Future<void> sendEmailVerification([
    ActionCodeSettings? actionCodeSettings,
  ]) async {
    await FirebaseTizenRuntime.ensureInitialized();
    await _auth._runAuthOperation(
      () => _delegate.sendEmailVerification(
        _auth._toDartActionCodeSettings(actionCodeSettings),
      ),
    );
  }

  @override
  Future<UserPlatform> unlink(String providerId) async {
    await FirebaseTizenRuntime.ensureInitialized();
    final firebase_dart.User user = await _auth._runAuthOperation(
      () => _delegate.unlink(providerId),
    );
    return _UserTizen(auth: _auth, user: user);
  }

  @override
  Future<void> updateEmail(String newEmail) async {
    await FirebaseTizenRuntime.ensureInitialized();
    await _auth._runAuthOperation(() => _delegate.updateEmail(newEmail));
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await FirebaseTizenRuntime.ensureInitialized();
    await _auth._runAuthOperation(() => _delegate.updatePassword(newPassword));
  }

  @override
  Future<void> updatePhoneNumber(PhoneAuthCredential phoneCredential) async {
    throw UnimplementedError(
      'Updating phone numbers is not supported on Tizen.',
    );
  }

  @override
  Future<void> updateProfile(Map<String, String?> profile) async {
    await FirebaseTizenRuntime.ensureInitialized();
    await _auth._runAuthOperation(
      () => _delegate.updateProfile(
        displayName: profile['displayName'],
        photoURL: profile['photoURL'],
      ),
    );
  }

  @override
  Future<void> verifyBeforeUpdateEmail(
    String newEmail, [
    ActionCodeSettings? actionCodeSettings,
  ]) async {
    await FirebaseTizenRuntime.ensureInitialized();
    await _auth._runAuthOperation(
      () => _delegate.verifyBeforeUpdateEmail(
        newEmail,
        _auth._toDartActionCodeSettings(actionCodeSettings),
      ),
    );
  }
}

class _UserCredentialTizen extends UserCredentialPlatform {
  _UserCredentialTizen({
    required super.auth,
    super.additionalUserInfo,
    super.credential,
    super.user,
  });
}

class _NoopMultiFactorPlatform extends MultiFactorPlatform {
  _NoopMultiFactorPlatform(super.auth);

  @override
  Future<void> enroll(
    MultiFactorAssertionPlatform assertion, {
    String? displayName,
  }) async {
    throw UnimplementedError('Multi-factor auth is not supported on Tizen.');
  }

  @override
  Future<List<MultiFactorInfo>> getEnrolledFactors() async {
    return <MultiFactorInfo>[];
  }

  @override
  Future<MultiFactorSession> getSession() async {
    throw UnimplementedError('Multi-factor auth is not supported on Tizen.');
  }

  @override
  Future<void> unenroll({
    String? factorUid,
    MultiFactorInfo? multiFactorInfo,
  }) async {
    throw UnimplementedError('Multi-factor auth is not supported on Tizen.');
  }
}
