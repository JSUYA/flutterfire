import 'package:firebase_database_platform_interface/firebase_database_platform_interface.dart';
import 'package:firebase_database_tizen/firebase_database_tizen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('registers FirebaseDatabaseTizen as the platform instance', () {
    FirebaseDatabaseTizen.register();

    expect(DatabasePlatform.instance, isA<FirebaseDatabaseTizen>());
  });
}
