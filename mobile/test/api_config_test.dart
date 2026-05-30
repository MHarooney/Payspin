import 'package:flutter_test/flutter_test.dart';
import 'package:payspin_mobile/core/network/api_config.dart';

void main() {
  test('default dev baseUrl is recognised as a local host', () {
    // Tests run in debug mode, so the release guard must be a no-op even though
    // the default baseUrl points at localhost.
    expect(ApiConfig.isLocalHost, isTrue);
    expect(ApiConfig.assertValidForRelease, returnsNormally);
  });
}
