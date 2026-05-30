class BankAccount {
  const BankAccount({
    required this.id,
    required this.ibanLast4,
    required this.accountHolder,
    this.bankName,
    required this.verified,
  });

  final String id;
  final String ibanLast4;
  final String accountHolder;
  final String? bankName;
  final bool verified;
}
