import '../repositories/auth_repository.dart';
import '../repositories/bank_account_repository.dart';
import '../repositories/onboarding_repository.dart';
import '../validators/iban_validator.dart';

class CompleteOnboardingUseCase {
  CompleteOnboardingUseCase({
    required AuthRepository authRepository,
    required BankAccountRepository bankAccountRepository,
    required OnboardingRepository onboardingRepository,
  })  : _auth = authRepository,
        _bank = bankAccountRepository,
        _onboarding = onboardingRepository;

  final AuthRepository _auth;
  final BankAccountRepository _bank;
  final OnboardingRepository _onboarding;

  Future<void> call({
    required String displayName,
    required String fullName,
    required String iban,
    required String email,
    required String password,
    bool alreadyRegistered = false,
  }) async {
    if (!alreadyRegistered && !(await _auth.hasSession())) {
      await _auth.register(email: email, password: password, displayName: displayName);
    } else {
      final name = fullName.trim().isNotEmpty ? fullName.trim() : displayName;
      if (name.isNotEmpty) await _auth.updateDisplayName(name);
    }
    await _bank.addAccount(
      iban: IbanValidator.normalize(iban),
      accountHolder: fullName.trim(),
    );
    await _onboarding.setOnboardingComplete(true);
  }
}
