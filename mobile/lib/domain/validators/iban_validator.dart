/// IBAN validation — mirrors `@payspin/validators` Mod-97 check.
class IbanValidator {
  static const lengths = {
    'AD': 24, 'AE': 23, 'AL': 28, 'AT': 20, 'AZ': 28, 'BA': 20, 'BE': 16,
    'BG': 22, 'BH': 22, 'BR': 29, 'BY': 28, 'CH': 21, 'CR': 22, 'CY': 28,
    'CZ': 24, 'DE': 22, 'DK': 18, 'DO': 28, 'EE': 20, 'EG': 29, 'ES': 24,
    'FI': 18, 'FO': 18, 'FR': 27, 'GB': 22, 'GE': 22, 'GI': 23, 'GL': 18,
    'GR': 27, 'GT': 28, 'HR': 21, 'HU': 28, 'IE': 22, 'IL': 23, 'IS': 26,
    'IT': 27, 'JO': 30, 'KW': 30, 'KZ': 20, 'LB': 28, 'LC': 32, 'LI': 21,
    'LT': 20, 'LU': 20, 'LV': 21, 'MC': 27, 'MD': 24, 'ME': 22, 'MK': 19,
    'MR': 27, 'MT': 31, 'MU': 30, 'NL': 18, 'NO': 15, 'PK': 24, 'PL': 28,
    'PS': 29, 'PT': 25, 'QA': 29, 'RO': 24, 'RS': 22, 'SA': 24, 'SE': 24,
    'SI': 19, 'SK': 24, 'SM': 27, 'TN': 24, 'TR': 26, 'UA': 29, 'VG': 24,
    'XK': 20,
  };

  static String normalize(String raw) => raw.replaceAll(RegExp(r'\s+'), '').toUpperCase();

  static String? validate(String raw) {
    final normalized = normalize(raw);
    if (normalized.isEmpty) return 'IBAN is required';
    if (normalized.length < 15) return 'IBAN is too short';
    final country = normalized.length >= 2 ? normalized.substring(0, 2) : '';
    if (!RegExp(r'^[A-Z]{2}$').hasMatch(country)) return 'IBAN must start with a 2-letter country code';
    final expected = lengths[country];
    if (expected == null) return 'Unknown IBAN country code';
    if (normalized.length != expected) return 'IBAN length for $country should be $expected characters';
    if (!_checksumOk(normalized)) return 'Invalid IBAN — check the number';
    return null;
  }

  static bool _checksumOk(String normalized) {
    if (!RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z0-9]+$').hasMatch(normalized)) return false;
    final rearranged = normalized.substring(4) + normalized.substring(0, 4);
    final numeric = rearranged.replaceAllMapped(RegExp(r'[A-Z]'), (m) => (m.group(0)!.codeUnitAt(0) - 55).toString());
    var remainder = 0;
    for (final c in numeric.split('')) {
      remainder = (remainder * 10 + int.parse(c)) % 97;
    }
    return remainder == 1;
  }
}
