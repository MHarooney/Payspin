import '../validators/iban_validator.dart';

class ValidateIbanUseCase {
  String? call(String raw) => IbanValidator.validate(raw);
  String normalize(String raw) => IbanValidator.normalize(raw);
}
