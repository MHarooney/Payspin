/// Non-verifying demo gate for the phone step.
///
/// Real SMS verification is not wired yet (needs backend support), so this does
/// NOT prove ownership of a phone number. It only checks that the input *looks*
/// like a 6-digit code so the onboarding flow can advance during the preview.
class VerifyOtpUseCase {
  bool call(String code) {
    final trimmed = code.trim();
    return RegExp(r'^\d{6}$').hasMatch(trimmed);
  }
}
