part of '../firebase_core_tizen.dart';

class FirebaseApp extends FirebaseAppPlatform {
  FirebaseApp._(super.name, super.options);

  bool _isAutomaticDataCollectionEnabled = false;

  @override
  Future<void> delete() async {
    await FirebaseTizenRuntime.ensureInitialized();
    await firebase_dart.Firebase.app(name).delete();
  }

  @override
  bool get isAutomaticDataCollectionEnabled =>
      _isAutomaticDataCollectionEnabled;

  @override
  Future<void> setAutomaticDataCollectionEnabled(bool enabled) async {
    _isAutomaticDataCollectionEnabled = enabled;
  }

  @override
  Future<void> setAutomaticResourceManagementEnabled(bool enabled) async {}
}
