import 'package:flutter_test/flutter_test.dart';
import 'package:payspin_mobile/core/network/api_config.dart';

void main() {
  test('debug default targets cloud when API_URL unset', () {
    expect(ApiConfig.baseUrl, ApiConfig.productionUrl);
    expect(ApiConfig.isLocalHost, isFalse);
    expect(ApiConfig.assertValidForRelease, returnsNormally);
  });
}
