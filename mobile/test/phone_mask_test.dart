import 'package:flutter_test/flutter_test.dart';
import 'package:payspin_mobile/core/util/phone_mask.dart';

void main() {
  test('maskE164 hides middle digits', () {
    expect(maskE164('+31612345678'), '+31 6•• ••• ••78');
  });
}
