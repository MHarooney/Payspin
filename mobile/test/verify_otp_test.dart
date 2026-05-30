import 'package:flutter_test/flutter_test.dart';
import 'package:payspin_mobile/domain/usecases/verify_otp_usecase.dart';

void main() {
  test('accepts 6 digit stub OTP', () {
    final useCase = VerifyOtpUseCase();
    expect(useCase('123456'), isTrue);
    expect(useCase('12'), isFalse);
  });
}
