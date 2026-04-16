import 'package:cloud_functions_platform_interface/cloud_functions_platform_interface.dart';
import 'package:cloud_functions_tizen/cloud_functions_tizen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('registers FirebaseFunctionsTizen as the platform instance', () {
    FirebaseFunctionsTizen.register();

    expect(FirebaseFunctionsPlatform.instance, isA<FirebaseFunctionsTizen>());
  });
}
