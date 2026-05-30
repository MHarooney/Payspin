class PaymentLink {
  const PaymentLink({
    required this.id,
    required this.shortCode,
    this.amountCents,
    required this.currency,
    this.description,
    required this.status,
    required this.createdAt,
    required this.payUrl,
    required this.completedPaymentCount,
    required this.totalReceivedCents,
  });

  final String id;
  final String shortCode;
  final int? amountCents;
  final String currency;
  final String? description;
  final String status;
  final String createdAt;
  final String payUrl;
  final int completedPaymentCount;
  final int totalReceivedCents;

  String get amountLabel {
    if (amountCents == null) return 'Open amount';
    return '€${(amountCents! / 100).toStringAsFixed(2)}';
  }

  String get statusLabel {
    switch (status) {
      case 'ACTIVE':
        return 'Active';
      case 'SETTLED':
        return 'Paid';
      case 'EXPIRED':
        return 'Expired';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String get dateLabel {
    try {
      final d = DateTime.parse(createdAt);
      const months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
      return '${d.day} ${months[d.month - 1]}';
    } catch (_) {
      return '';
    }
  }
}

class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.amountCents,
    required this.status,
    this.payerBankName,
    required this.initiatedAt,
  });

  final String id;
  final int amountCents;
  final String status;
  final String? payerBankName;
  final String initiatedAt;

  String get amountLabel => '€${(amountCents / 100).toStringAsFixed(2)}';
}

class PaymentLinkDetail extends PaymentLink {
  const PaymentLinkDetail({
    required super.id,
    required super.shortCode,
    super.amountCents,
    required super.currency,
    super.description,
    required super.status,
    required super.createdAt,
    required super.payUrl,
    required super.completedPaymentCount,
    required super.totalReceivedCents,
    required this.payments,
  });

  final List<PaymentRecord> payments;
}
