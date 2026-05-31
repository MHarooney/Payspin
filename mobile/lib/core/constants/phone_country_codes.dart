/// European + Egypt dial codes for onboarding SMS. NL and DE listed first (primary markets).
class PhoneCountry {
  const PhoneCountry({
    required this.isoCode,
    required this.dialCode,
    required this.name,
  });

  final String isoCode;
  final String dialCode;
  final String name;

  String get flagEmoji => isoToFlagEmoji(isoCode);

  bool matchesQuery(String raw) {
    final q = raw.trim().toLowerCase();
    if (q.isEmpty) return true;
    final digits = q.replaceAll(RegExp(r'\D'), '');
    return name.toLowerCase().contains(q) ||
        isoCode.toLowerCase().contains(q) ||
        dialCode.toLowerCase().contains(q) ||
        (digits.isNotEmpty && dialCode.contains(digits));
  }
}

/// Unicode regional-indicator flags from ISO 3166-1 alpha-2 (no asset pack).
String isoToFlagEmoji(String isoCode) {
  if (isoCode.length != 2) return '';
  final upper = isoCode.toUpperCase();
  return String.fromCharCodes([
    0x1F1E6 + upper.codeUnitAt(0) - 0x41,
    0x1F1E6 + upper.codeUnitAt(1) - 0x41,
  ]);
}

const String kDefaultPhoneCountryCode = '+31';

const List<PhoneCountry> kPhoneCountries = [
  PhoneCountry(isoCode: 'NL', dialCode: '+31', name: 'Netherlands'),
  PhoneCountry(isoCode: 'DE', dialCode: '+49', name: 'Germany'),
  PhoneCountry(isoCode: 'AT', dialCode: '+43', name: 'Austria'),
  PhoneCountry(isoCode: 'BE', dialCode: '+32', name: 'Belgium'),
  PhoneCountry(isoCode: 'BG', dialCode: '+359', name: 'Bulgaria'),
  PhoneCountry(isoCode: 'HR', dialCode: '+385', name: 'Croatia'),
  PhoneCountry(isoCode: 'CY', dialCode: '+357', name: 'Cyprus'),
  PhoneCountry(isoCode: 'CZ', dialCode: '+420', name: 'Czechia'),
  PhoneCountry(isoCode: 'DK', dialCode: '+45', name: 'Denmark'),
  PhoneCountry(isoCode: 'EE', dialCode: '+372', name: 'Estonia'),
  PhoneCountry(isoCode: 'EG', dialCode: '+20', name: 'Egypt'),
  PhoneCountry(isoCode: 'FI', dialCode: '+358', name: 'Finland'),
  PhoneCountry(isoCode: 'FR', dialCode: '+33', name: 'France'),
  PhoneCountry(isoCode: 'GR', dialCode: '+30', name: 'Greece'),
  PhoneCountry(isoCode: 'HU', dialCode: '+36', name: 'Hungary'),
  PhoneCountry(isoCode: 'IS', dialCode: '+354', name: 'Iceland'),
  PhoneCountry(isoCode: 'IE', dialCode: '+353', name: 'Ireland'),
  PhoneCountry(isoCode: 'IT', dialCode: '+39', name: 'Italy'),
  PhoneCountry(isoCode: 'LV', dialCode: '+371', name: 'Latvia'),
  PhoneCountry(isoCode: 'LT', dialCode: '+370', name: 'Lithuania'),
  PhoneCountry(isoCode: 'LU', dialCode: '+352', name: 'Luxembourg'),
  PhoneCountry(isoCode: 'MT', dialCode: '+356', name: 'Malta'),
  PhoneCountry(isoCode: 'NO', dialCode: '+47', name: 'Norway'),
  PhoneCountry(isoCode: 'PL', dialCode: '+48', name: 'Poland'),
  PhoneCountry(isoCode: 'PT', dialCode: '+351', name: 'Portugal'),
  PhoneCountry(isoCode: 'RO', dialCode: '+40', name: 'Romania'),
  PhoneCountry(isoCode: 'SK', dialCode: '+421', name: 'Slovakia'),
  PhoneCountry(isoCode: 'SI', dialCode: '+386', name: 'Slovenia'),
  PhoneCountry(isoCode: 'ES', dialCode: '+34', name: 'Spain'),
  PhoneCountry(isoCode: 'SE', dialCode: '+46', name: 'Sweden'),
  PhoneCountry(isoCode: 'CH', dialCode: '+41', name: 'Switzerland'),
  PhoneCountry(isoCode: 'GB', dialCode: '+44', name: 'United Kingdom'),
];

PhoneCountry? phoneCountryByDialCode(String dialCode) {
  for (final c in kPhoneCountries) {
    if (c.dialCode == dialCode) return c;
  }
  return null;
}

PhoneCountry get defaultPhoneCountry =>
    phoneCountryByDialCode(kDefaultPhoneCountryCode)!;

bool isSupportedPhoneCountryCode(String dialCode) =>
    phoneCountryByDialCode(dialCode) != null;
