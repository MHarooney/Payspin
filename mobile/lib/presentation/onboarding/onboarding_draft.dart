import 'package:equatable/equatable.dart';

class OnboardingDraft extends Equatable {
  const OnboardingDraft({
    this.displayName = '',
    this.countryCode = '+31',
    this.phone = '',
    this.email = '',
    this.password = '',
    this.iban = '',
    this.fullName = '',
    this.otpVerified = false,
  });

  final String displayName;
  final String countryCode;
  final String phone;
  final String email;
  final String password;
  final String iban;
  final String fullName;
  final bool otpVerified;

  OnboardingDraft copyWith({
    String? displayName,
    String? countryCode,
    String? phone,
    String? email,
    String? password,
    String? iban,
    String? fullName,
    bool? otpVerified,
  }) {
    return OnboardingDraft(
      displayName: displayName ?? this.displayName,
      countryCode: countryCode ?? this.countryCode,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      password: password ?? this.password,
      iban: iban ?? this.iban,
      fullName: fullName ?? this.fullName,
      otpVerified: otpVerified ?? this.otpVerified,
    );
  }

  String get phoneDisplay => '$countryCode $phone'.trim();

  /// Privacy-safe subtitle for OTP (e.g. `+31 ••••••8902`).
  String get phoneMasked {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return phoneDisplay;
    final last4 = digits.substring(digits.length - 4);
    return '$countryCode ••••••$last4';
  }

  String get ibanDisplay {
    final n = iban.replaceAll(' ', '').toUpperCase();
    if (n.length < 8) return n.isEmpty ? '—' : n;
    return '${n.substring(0, 4)} •••• ${n.substring(n.length - 4)}';
  }

  @override
  List<Object?> get props => [displayName, countryCode, phone, email, password, iban, fullName, otpVerified];
}
