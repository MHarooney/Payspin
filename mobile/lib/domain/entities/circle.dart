class CircleMember {
  const CircleMember({
    required this.id,
    required this.userId,
    this.displayName,
    required this.payoutOrder,
    required this.status,
    required this.isCurrentRecipient,
  });

  final String id;
  final String userId;
  final String? displayName;
  final int payoutOrder;
  final String status;
  final bool isCurrentRecipient;

  String get label => displayName?.trim().isNotEmpty == true ? displayName! : 'Member ${payoutOrder + 1}';
}

class Circle {
  const Circle({
    required this.id,
    required this.name,
    required this.status,
    required this.memberCount,
    required this.activeMemberCount,
    required this.contributionCents,
    required this.cycleDurationDays,
    required this.currentRound,
    required this.hostUserId,
    required this.isHost,
    this.inviteCode,
    this.startedAt,
    required this.createdAt,
    this.members = const [],
    this.currentRecipientDisplayName,
  });

  final String id;
  final String name;
  final String status;
  final int memberCount;
  final int activeMemberCount;
  final int contributionCents;
  final int cycleDurationDays;
  final int currentRound;
  final String hostUserId;
  final bool isHost;
  final String? inviteCode;
  final String? startedAt;
  final String createdAt;
  final List<CircleMember> members;
  final String? currentRecipientDisplayName;

  String get contributionLabel => '€${(contributionCents / 100).toStringAsFixed(2)}';

  String get statusLabel {
    switch (status) {
      case 'DRAFT':
        return 'Draft';
      case 'ACTIVE':
        return 'Active';
      case 'COMPLETED':
        return 'Completed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String get usageLabel => '$activeMemberCount / $memberCount members';

  String get roundLabel {
    if (status == 'DRAFT') return 'Not started';
    if (status == 'COMPLETED') return 'All rounds complete';
    return 'Round ${currentRound + 1} of $memberCount';
  }

  bool get canActivate => isHost && status == 'DRAFT' && activeMemberCount >= memberCount;

  bool get canAdvance => isHost && status == 'ACTIVE';

  bool get canCreateContributionLink => isHost && status == 'ACTIVE';

  CircleMember? get currentRecipient {
    for (final m in members) {
      if (m.isCurrentRecipient) return m;
    }
    return null;
  }
}

class CircleContributionLink {
  const CircleContributionLink({required this.payUrl});

  final String payUrl;
}
