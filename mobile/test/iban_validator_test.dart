import 'package:flutter_test/flutter_test.dart';
import 'package:payspin_mobile/domain/validators/iban_validator.dart';

void main() {
  test('validates DE IBAN', () {
    expect(IbanValidator.validate('DE89370400440532013000'), isNull);
  });

  test('rejects short IBAN', () {
    expect(IbanValidator.validate('DE32 4234 25'), 'IBAN is too short');
  });
}
