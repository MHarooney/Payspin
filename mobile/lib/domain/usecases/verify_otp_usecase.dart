class VerifyOtpUseCase {
  /// Stub OTP — accepts any 6-digit code (dev: 123456).
  bool call(String code) {
    final trimmed = code.trim();
    return RegExp(r'^\d{6}$').hasMatch(trimmed);
  }
}
