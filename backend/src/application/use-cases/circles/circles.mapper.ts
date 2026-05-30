import { CircleDetail, CircleMemberView, CircleSummary } from '@payspin/shared-types';
import { Injectable } from '@nestjs/common';

type CircleRow = {
  id: string;
  name: string;
  hostUserId: string;
  memberCount: number;
  contributionCents: number;
  cycleDurationDays: number;
  inviteCode: string;
  status: string;
  currentRound: number;
  startedAt: Date | null;
  createdAt: Date;
};

type MemberRow = {
  id: string;
  userId: string;
  payoutOrder: number;
  status: string;
};

@Injectable()
export class CirclesMapper {
  toSummary(
    circle: CircleRow,
    viewerUserId: string,
    activeMemberCount: number,
  ): CircleSummary {
    const isHost = circle.hostUserId === viewerUserId;
    return {
      id: circle.id,
      name: circle.name,
      status: circle.status as CircleSummary['status'],
      memberCount: circle.memberCount,
      activeMemberCount,
      contributionCents: circle.contributionCents,
      cycleDurationDays: circle.cycleDurationDays,
      currentRound: circle.currentRound,
      hostUserId: circle.hostUserId,
      isHost,
      inviteCode: isHost ? circle.inviteCode : null,
      startedAt: circle.startedAt?.toISOString() ?? null,
      createdAt: circle.createdAt.toISOString(),
    };
  }

  toDetail(
    circle: CircleRow,
    viewerUserId: string,
    members: MemberRow[],
    displayNames: Map<string, string | null>,
  ): CircleDetail {
    const activeMembers = members.filter((m) => m.status === 'ACTIVE');
    const summary = this.toSummary(circle, viewerUserId, activeMembers.length);
    const memberViews: CircleMemberView[] = members
      .filter((m) => m.status === 'ACTIVE')
      .sort((a, b) => a.payoutOrder - b.payoutOrder)
      .map((m) => ({
        id: m.id,
        userId: m.userId,
        displayName: displayNames.get(m.userId) ?? null,
        payoutOrder: m.payoutOrder,
        status: m.status as CircleMemberView['status'],
        isCurrentRecipient:
          circle.status === 'ACTIVE' && m.payoutOrder === circle.currentRound,
      }));

    const recipient = memberViews.find((m) => m.isCurrentRecipient);

    return {
      ...summary,
      members: memberViews,
      currentRecipientDisplayName: recipient?.displayName ?? null,
    };
  }
}
