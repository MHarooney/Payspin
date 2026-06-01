class BankAccount {
  const BankAccount({
    required this.id,
    required this.ibanLast4,
    required this.accountHolder,
    this.bankName,
    required this.verified,
    this.isPrimary = false,
  });

  final String id;
  final String ibanLast4;
  final String accountHolder;
  final String? bankName;
  final bool verified;

  /// The account new payment links default to. Exactly one per user.
  final bool isPrimary;
}
