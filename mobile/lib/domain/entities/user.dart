class User {
  const User({
    required this.id,
    required this.email,
    this.displayName,
    this.phoneE164,
    this.phoneVerified = false,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? phoneE164;
  final bool phoneVerified;
  final String createdAt;

  /// True when the account was created from a phone number rather than a real
  /// email address. These accounts use a synthetic `{digits}@phone.payspin.app`
  /// login and should never surface that address to the user.
  bool get isPhoneAccount => email.endsWith('@phone.payspin.app');

  /// The line to show under the user's name on the profile: their real phone
  /// number when available, otherwise a real email — never the synthetic
  /// phone-login address (which looks like a raw number and gets confused with
  /// the IBAN).
  String get contactLabel {
    final phone = phoneE164?.trim();
    if (phone != null && phone.isNotEmpty) return phone;
    return isPhoneAccount ? '' : email;
  }

  /// First token of [displayName], or the email local-part for email accounts.
  /// Returns null for phone-only accounts with no display name set.
  String? get greetingFirstName {
    final dn = displayName?.trim();
    if (dn != null && dn.isNotEmpty) {
      return dn.split(RegExp(r'\s+')).first;
    }
    if (!isPhoneAccount) {
      final local = email.split('@').first.trim();
      if (local.isNotEmpty) return local;
    }
    return null;
  }
}
