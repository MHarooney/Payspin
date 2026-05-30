import '../../domain/entities/auth_session.dart';
import '../../domain/entities/bank_account.dart';
import '../../domain/entities/payment_link.dart';
import '../../domain/entities/user.dart';

User mapUser(Map<String, dynamic> json) => User(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      createdAt: json['createdAt'] as String,
    );

AuthSession mapAuthSession(Map<String, dynamic> json) => AuthSession(
      accessToken: json['accessToken'] as String,
      user: mapUser(json['user'] as Map<String, dynamic>),
    );

BankAccount mapBankAccount(Map<String, dynamic> json) => BankAccount(
      id: json['id'] as String,
      ibanLast4: json['ibanLast4'] as String,
      accountHolder: json['accountHolder'] as String,
      bankName: json['bankName'] as String?,
      verified: json['verified'] as bool? ?? false,
    );

PaymentLink mapPaymentLink(Map<String, dynamic> json) => PaymentLink(
      id: json['id'] as String,
      shortCode: json['shortCode'] as String,
      amountCents: json['amountCents'] as int?,
      currency: json['currency'] as String? ?? 'EUR',
      description: json['description'] as String?,
      status: json['status'] as String,
      createdAt: json['createdAt'] as String,
      payUrl: json['payUrl'] as String,
      completedPaymentCount: (json['completedPaymentCount'] as num?)?.toInt() ?? 0,
      totalReceivedCents: (json['totalReceivedCents'] as num?)?.toInt() ?? 0,
    );

PaymentLinkDetail mapPaymentLinkDetail(Map<String, dynamic> json) {
  final payments = (json['payments'] as List<dynamic>? ?? [])
      .map((e) => e as Map<String, dynamic>)
      .map(
        (p) => PaymentRecord(
          id: p['id'] as String,
          amountCents: (p['amountCents'] as num).toInt(),
          status: p['status'] as String,
          payerBankName: p['payerBankName'] as String?,
          initiatedAt: p['initiatedAt'] as String,
        ),
      )
      .toList();
  return PaymentLinkDetail(
    id: json['id'] as String,
    shortCode: json['shortCode'] as String,
    amountCents: json['amountCents'] as int?,
    currency: json['currency'] as String? ?? 'EUR',
    description: json['description'] as String?,
    status: json['status'] as String,
    createdAt: json['createdAt'] as String,
    payUrl: json['payUrl'] as String,
    completedPaymentCount: (json['completedPaymentCount'] as num?)?.toInt() ?? 0,
    totalReceivedCents: (json['totalReceivedCents'] as num?)?.toInt() ?? 0,
    payments: payments,
  );
}
