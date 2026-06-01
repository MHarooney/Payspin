import '../../domain/entities/auth_session.dart';
import '../../domain/entities/bank_account.dart';
import '../../domain/entities/circle.dart';
import '../../domain/entities/institution.dart';
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
      isPrimary: json['isPrimary'] as bool? ?? false,
    );

Institution mapInstitution(Map<String, dynamic> json) => Institution(
      id: json['id'] as String,
      name: json['name'] as String? ?? json['fullName'] as String? ?? 'Bank',
      fullName: json['fullName'] as String? ?? json['name'] as String? ?? 'Bank',
    );

BankConnectionStart mapBankConnectionStart(Map<String, dynamic> json) =>
    BankConnectionStart(
      connectionId: json['connectionId'] as String,
      authorisationUrl: json['authorisationUrl'] as String,
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
      linkType: json['linkType'] as String? ?? 'SINGLE',
      maxUses: (json['maxUses'] as num?)?.toInt(),
      useCount: (json['useCount'] as num?)?.toInt() ?? 0,
      expiresAt: json['expiresAt'] as String?,
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
    linkType: json['linkType'] as String? ?? 'SINGLE',
    maxUses: (json['maxUses'] as num?)?.toInt(),
    useCount: (json['useCount'] as num?)?.toInt() ?? 0,
    expiresAt: json['expiresAt'] as String?,
    payments: payments,
  );
}

CircleMember mapCircleMember(Map<String, dynamic> json) => CircleMember(
      id: json['id'] as String,
      userId: json['userId'] as String,
      displayName: json['displayName'] as String?,
      payoutOrder: (json['payoutOrder'] as num).toInt(),
      status: json['status'] as String,
      isCurrentRecipient: json['isCurrentRecipient'] as bool? ?? false,
    );

Circle mapCircleSummary(Map<String, dynamic> json) => Circle(
      id: json['id'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
      memberCount: (json['memberCount'] as num).toInt(),
      activeMemberCount: (json['activeMemberCount'] as num).toInt(),
      contributionCents: (json['contributionCents'] as num).toInt(),
      cycleDurationDays: (json['cycleDurationDays'] as num).toInt(),
      currentRound: (json['currentRound'] as num).toInt(),
      hostUserId: json['hostUserId'] as String,
      isHost: json['isHost'] as bool? ?? false,
      inviteCode: json['inviteCode'] as String?,
      startedAt: json['startedAt'] as String?,
      createdAt: json['createdAt'] as String,
    );

Circle mapCircleDetail(Map<String, dynamic> json) {
  final members = (json['members'] as List<dynamic>? ?? [])
      .map((e) => mapCircleMember(e as Map<String, dynamic>))
      .toList();
  return Circle(
    id: json['id'] as String,
    name: json['name'] as String,
    status: json['status'] as String,
    memberCount: (json['memberCount'] as num).toInt(),
    activeMemberCount: (json['activeMemberCount'] as num).toInt(),
    contributionCents: (json['contributionCents'] as num).toInt(),
    cycleDurationDays: (json['cycleDurationDays'] as num).toInt(),
    currentRound: (json['currentRound'] as num).toInt(),
    hostUserId: json['hostUserId'] as String,
    isHost: json['isHost'] as bool? ?? false,
    inviteCode: json['inviteCode'] as String?,
    startedAt: json['startedAt'] as String?,
    createdAt: json['createdAt'] as String,
    members: members,
    currentRecipientDisplayName: json['currentRecipientDisplayName'] as String?,
  );
}
