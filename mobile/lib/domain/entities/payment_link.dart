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
    this.linkType = 'SINGLE',
    this.maxUses,
    this.useCount = 0,
    this.expiresAt,
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
  final String linkType;
  final int? maxUses;
  final int useCount;
  final String? expiresAt;

  bool get isMulti => linkType == 'MULTI';

  bool get isExpired {
    final raw = expiresAt;
    if (raw == null) return status == 'EXPIRED';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return status == 'EXPIRED';
    return status == 'EXPIRED' || parsed.isBefore(DateTime.now());
  }

  /// True when a payer can still pay this link.
  bool get isPayable =>
      (status == 'ACTIVE' || status == 'COLLECTING') && !isExpired;

  /// Whether a cancel action should be offered (only meaningful while open).
  bool get canCancel => status == 'ACTIVE' || status == 'COLLECTING';

  /// Closed links that can spawn a new request with the same amount/description.
  bool get canRequestAgain =>
      !isPayable &&
      (status == 'CANCELLED' || status == 'SETTLED' || status == 'EXPIRED');

  String get amountLabel {
    if (amountCents == null) return 'Open amount';
    return '€${(amountCents! / 100).toStringAsFixed(2)}';
  }

  String get statusLabel {
    switch (status) {
      case 'ACTIVE':
        return 'Active';
      case 'COLLECTING':
        return 'Collecting';
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

  /// For MULTI links, a "used X of N" (or "X received" when uncapped) summary.
  /// Returns null for SINGLE links so callers can hide it.
  String? get usageLabel {
    if (!isMulti) return null;
    if (maxUses != null) return 'Used $useCount of $maxUses';
    return '$useCount received';
  }

  String get totalReceivedLabel => '€${(totalReceivedCents / 100).toStringAsFixed(2)}';

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

  /// Human-readable label for a backend PaymentStatus enum value.
  String get statusLabel => paymentStatusLabel(status);

  /// A payment is terminal when it will not change again without a new action.
  bool get isTerminal =>
      status == 'COMPLETED' || status == 'FAILED' || status == 'CANCELLED';
}

/// Maps a backend `PaymentStatus` enum to friendly UI text.
String paymentStatusLabel(String status) {
  switch (status) {
    case 'AWAITING_AUTHORIZATION':
      return 'Awaiting bank';
    case 'PENDING':
      return 'Pending';
    case 'PROCESSING':
      return 'Processing';
    case 'COMPLETED':
      return 'Paid';
    case 'FAILED':
      return 'Failed';
    case 'CANCELLED':
      return 'Cancelled';
    default:
      return status;
  }
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
    super.linkType,
    super.maxUses,
    super.useCount,
    super.expiresAt,
    required this.payments,
  });

  final List<PaymentRecord> payments;

  /// True while any payment is still settling — used to drive status polling.
  bool get hasPendingPayments => payments.any((p) => !p.isTerminal);
}
