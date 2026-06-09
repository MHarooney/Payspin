/// Masks an E.164 phone for display, e.g. `+31612345678` → `+31 6•• ••• ••78`.
String maskE164(String phone) {
  final trimmed = phone.trim();
  if (trimmed.isEmpty) return trimmed;

  final hasPlus = trimmed.startsWith('+');
  final digits = trimmed.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 8) return trimmed;

  final last2 = digits.substring(digits.length - 2);
  final country = digits.substring(0, 2);
  final national = digits.substring(2);

  if (national.isEmpty) return trimmed;

  final first = national[0];
  return '${hasPlus ? '+' : ''}$country $first•• ••• ••$last2';
}
