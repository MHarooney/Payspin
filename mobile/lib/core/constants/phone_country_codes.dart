/// E.164 dial codes for onboarding phone entry. NL and DE first (primary markets).
typedef PhoneCountryOption = (String dialCode, String label);

const List<PhoneCountryOption> kPhoneCountryCodes = [
  ('+31', 'NL'),
  ('+49', 'DE'),
  ('+43', 'AT'),
  ('+32', 'BE'),
  ('+359', 'BG'),
  ('+385', 'HR'),
  ('+357', 'CY'),
  ('+420', 'CZ'),
  ('+45', 'DK'),
  ('+372', 'EE'),
  ('+358', 'FI'),
  ('+33', 'FR'),
  ('+30', 'GR'),
  ('+36', 'HU'),
  ('+354', 'IS'),
  ('+353', 'IE'),
  ('+39', 'IT'),
  ('+371', 'LV'),
  ('+370', 'LT'),
  ('+352', 'LU'),
  ('+356', 'MT'),
  ('+47', 'NO'),
  ('+48', 'PL'),
  ('+351', 'PT'),
  ('+40', 'RO'),
  ('+421', 'SK'),
  ('+386', 'SI'),
  ('+34', 'ES'),
  ('+46', 'SE'),
  ('+41', 'CH'),
  ('+44', 'GB'),
  ('+20', 'EG'),
  ('+1', 'US'),
];

const String kDefaultPhoneCountryCode = '+31';

bool isSupportedPhoneCountryCode(String dialCode) =>
    kPhoneCountryCodes.any((c) => c.$1 == dialCode);
