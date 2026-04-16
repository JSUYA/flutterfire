import 'firebase_backend_config.dart';
import 'firebase_user_session.dart';

abstract interface class FirebaseExperimentalBackend {
  Future<void> initialize(FirebaseBackendConfig config);

  Future<FirebaseUserSession> signInWithEmailAndPassword(
    String email,
    String password,
  );

  Future<Object?> callFunction(
    String name, {
    Object? data,
    String region = 'us-central1',
  });

  Future<void> dispose();
}
