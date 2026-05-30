import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/errors/api_exception.dart';
import '../../domain/usecases/complete_onboarding_usecase.dart';
import '../../domain/usecases/validate_iban_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';
import 'onboarding_draft.dart';

class OnboardingCubit extends Cubit<OnboardingDraft> {
  OnboardingCubit({
    required VerifyOtpUseCase verifyOtp,
    required ValidateIbanUseCase validateIban,
    required CompleteOnboardingUseCase completeOnboarding,
  })  : _verifyOtp = verifyOtp,
        _validateIban = validateIban,
        _completeOnboarding = completeOnboarding,
        super(const OnboardingDraft());

  final VerifyOtpUseCase _verifyOtp;
  final ValidateIbanUseCase _validateIban;
  final CompleteOnboardingUseCase _completeOnboarding;

  String? lastError;
  bool isLoading = false;

  void updateDisplayName(String v) => emit(state.copyWith(displayName: v));
  void updatePhone(String v) => emit(state.copyWith(phone: v));
  void updateCountry(String v) => emit(state.copyWith(countryCode: v));
  void updateEmail(String v) => emit(state.copyWith(email: v));
  void updatePassword(String v) => emit(state.copyWith(password: v));
  void updateIban(String v) => emit(state.copyWith(iban: v.toUpperCase()));
  void updateFullName(String v) => emit(state.copyWith(fullName: v));

  bool verifyOtpCode(String code) {
    final ok = _verifyOtp(code);
    if (ok) emit(state.copyWith(otpVerified: true));
    return ok;
  }

  String? validateIbanField() => _validateIban(state.iban);

  Future<bool> complete({bool alreadyRegistered = false}) async {
    isLoading = true;
    lastError = null;
    try {
      await _completeOnboarding(
        displayName: state.displayName.trim(),
        fullName: state.fullName.trim(),
        iban: state.iban,
        email: state.email.trim(),
        password: state.password,
        alreadyRegistered: alreadyRegistered,
      );
      return true;
    } catch (e) {
      lastError = apiErrorMessage(e);
      return false;
    } finally {
      isLoading = false;
    }
  }
}
