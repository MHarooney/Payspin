import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/errors/api_exception.dart';
import '../../core/firebase/phone_auth_service.dart';
import '../../core/onboarding/onboarding_progress.dart';
import '../../core/onboarding/onboarding_progress_store.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/complete_onboarding_usecase.dart';
import '../../domain/usecases/validate_iban_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';
import 'onboarding_draft.dart';

class OnboardingCubit extends Cubit<OnboardingDraft> {
  OnboardingCubit({
    required VerifyOtpUseCase verifyOtp,
    required ValidateIbanUseCase validateIban,
    required CompleteOnboardingUseCase completeOnboarding,
    required AuthRepository authRepository,
    required OnboardingProgressStore progressStore,
  })  : _verifyOtp = verifyOtp,
        _validateIban = validateIban,
        _completeOnboarding = completeOnboarding,
        _auth = authRepository,
        _progressStore = progressStore,
        super(const OnboardingDraft());

  final VerifyOtpUseCase _verifyOtp;
  final ValidateIbanUseCase _validateIban;
  final CompleteOnboardingUseCase _completeOnboarding;
  final AuthRepository _auth;
  final OnboardingProgressStore _progressStore;

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

  /// Marks the phone verified after a successful real (Firebase) SMS check.
  void markPhoneVerified() => emit(state.copyWith(otpVerified: true));

  /// Persists the current phone step so the OTP screen can be restored after an
  /// app restart triggered by the external reCAPTCHA flow.
  Future<void> savePhoneProgress({
    String? verificationId,
    required bool codeSent,
  }) {
    return _progressStore.save(
      OnboardingProgress(
        countryCode: state.countryCode,
        phone: state.phone,
        displayName: state.displayName,
        verificationId: verificationId,
        codeSent: codeSent,
        savedAt: DateTime.now(),
      ),
    );
  }

  /// Rehydrates the draft from a persisted in-progress verification on cold
  /// start. Returns the loaded progress (with [OnboardingProgress.verificationId])
  /// or null when there is nothing valid to restore.
  Future<OnboardingProgress?> restorePhoneProgress() async {
    final progress = await _progressStore.load();
    if (progress == null) return null;
    emit(state.copyWith(
      countryCode: progress.countryCode,
      phone: progress.phone,
      displayName: progress.displayName,
    ));
    return progress;
  }

  /// Drops any persisted phone progress (after success or explicit back/cancel).
  Future<void> clearPhoneProgress() => _progressStore.clear();

  /// Creates (or resumes) a Payspin session from the verified phone.
  ///
  /// The verified Firebase E.164 number is the account identity: the backend
  /// `/auth/phone` endpoint logs into the existing account when the number is
  /// already registered, so re-onboarding the same phone never spawns a
  /// duplicate account. Falls back to the legacy synthetic-email register only
  /// when Firebase is unavailable (e.g. local dev without phone auth).
  Future<bool> ensureAccountFromPhone(PhoneAuthService phoneAuth) async {
    isLoading = true;
    lastError = null;
    try {
      if (await _auth.hasSession()) {
        await phoneAuth.syncVerifiedPhone();
        return true;
      }

      final idToken = await phoneAuth.currentIdToken();
      if (idToken != null) {
        await _auth.phoneSignIn(
          idToken: idToken,
          displayName: state.displayName.trim().isEmpty ? null : state.displayName.trim(),
        );
        return true;
      }

      // Firebase unavailable: legacy path keeps local dev / demo onboarding
      // working. Identity here is the typed digits, which is acceptable only
      // because real (Firebase-backed) builds always take the path above.
      final digits = state.phone.replaceAll(RegExp(r'\D'), '');
      if (digits.length < 6) {
        lastError = 'Enter a valid phone number';
        return false;
      }
      final email = '$digits@phone.payspin.app';
      final password = _generatePassword();
      await _auth.register(
        email: email,
        password: password,
        displayName: state.displayName.trim().isEmpty ? null : state.displayName.trim(),
      );
      emit(state.copyWith(email: email, password: password));
      await phoneAuth.syncVerifiedPhone();
      return true;
    } catch (e) {
      lastError = apiErrorMessage(e);
      return false;
    } finally {
      isLoading = false;
    }
  }

  String _generatePassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure();
    return List.generate(32, (_) => chars[rand.nextInt(chars.length)]).join();
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
