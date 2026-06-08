import { Injectable } from '@nestjs/common';
import { AdminCircleDetail, AdminCircleListItem, AdminCircleMember } from '@payspin/shared-types';
import type { Circle, CircleMember, User } from '@prisma/client';

@Injectable()
export class CirclesAdminMapper {
  toListItem(circle: Circle, activeMemberCount: number): AdminCircleListItem {
    const potCents = circle.contributionCents * circle.memberCount;
    const escrowCents = circle.contributionCents * activeMemberCount;
    return {
      id: circle.id,
      name: circle.name,
      status: circle.status,
      memberCount: circle.memberCount,
      activeMemberCount,
      contributionCents: circle.contributionCents,
      potCents,
      cycleDurationDays: circle.cycleDurationDays,
      currentRound: circle.currentRound,
      escrowCents,
      smartContractAddress: circle.smartContractAddress,
      startedAt: circle.startedAt?.toISOString() ?? null,
      createdAt: circle.createdAt.toISOString(),
    };
  }

  toDetail(
    circle: Circle,
    members: (CircleMember & { user?: Pick<User, 'displayName'> | null })[],
    host: Pick<User, 'displayName'> | null,
  ): AdminCircleDetail {
    const active = members.filter((m) => m.status === 'ACTIVE');
    const mapped: AdminCircleMember[] = members
      .sort((a, b) => a.payoutOrder - b.payoutOrder)
      .map((m) => ({
        id: m.id,
        userId: m.userId,
        displayName: m.user?.displayName ?? null,
        payoutOrder: m.payoutOrder,
        status: m.status,
        isCurrentRecipient: m.payoutOrder === circle.currentRound,
      }));

    return {
      ...this.toListItem(circle, active.length),
      hostUserId: circle.hostUserId,
      hostName: host?.displayName ?? null,
      members: mapped,
    };
  }
}
