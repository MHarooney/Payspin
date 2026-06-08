import { Injectable, NotFoundException } from '@nestjs/common';
import {
  AdminUserDetail,
  AdminPaymentListItem,
  AdminPaymentStatus,
  AdminUserBankAccount,
  AdminUserCircleSummary,
  AdminUserStateDto,
  AuditEventDto,
  AdminUserDevice,
  AdminPaymentLinkListItem,
} from '@payspin/shared-types';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { computePresence } from '../../../domain/presence';

@Injectable()
export class GetUserDetailAdminUseCase {
  constructor(private readonly prisma: PrismaService) {}

  async execute(userId: string): Promise<AdminUserDetail> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        bankAccounts: true,
        deviceTokens: { orderBy: { updatedAt: 'desc' } },
      },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const [
      adminState,
      paymentCount,
      paymentLinkCount,
      volumeAgg,
      recentPaymentsRaw,
      circlesAsHost,
      memberships,
      recentLinksRaw,
      auditEventsRaw,
    ] = await Promise.all([
      this.prisma.userAdminState.findUnique({ where: { userId } }),
      this.prisma.payment.count({ where: { paymentLink: { payeeUserId: userId } } }),
      this.prisma.paymentLink.count({ where: { payeeUserId: userId } }),
      this.prisma.payment.aggregate({
        _sum: { amountCents: true },
        where: { status: 'COMPLETED', paymentLink: { payeeUserId: userId } },
      }),
      this.prisma.payment.findMany({
        where: { paymentLink: { payeeUserId: userId } },
        take: 10,
        orderBy: { initiatedAt: 'desc' },
        include: {
          paymentLink: { select: { shortCode: true } },
        },
      }),
      this.prisma.circle.findMany({
        where: { hostUserId: userId },
        select: { id: true, name: true, status: true },
        take: 20,
      }),
      this.prisma.circleMember.findMany({
        where: { userId },
        select: { circleId: true, payoutOrder: true, circle: { select: { id: true, name: true, status: true } } },
        take: 20,
      }),
      this.prisma.paymentLink.findMany({
        where: { payeeUserId: userId },
        take: 10,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.adminAuditEvent.findMany({
        where: { targetId: userId, targetType: 'user' },
        orderBy: { createdAt: 'desc' },
        take: 20,
      }),
    ]);

    const bankAccounts: AdminUserBankAccount[] = user.bankAccounts.map((b) => ({
      id: b.id,
      ibanLast4: b.ibanLast4,
      bankName: b.bankName,
      accountHolder: b.accountHolder,
      verified: b.verified,
      isPrimary: b.isPrimary,
    }));

    const recentPayments: AdminPaymentListItem[] = recentPaymentsRaw.map((p) => ({
      id: p.id,
      shortCode: p.paymentLink.shortCode,
      payeeName: user.displayName ?? user.email,
      payerBankName: p.payerBankName,
      amountCents: p.amountCents,
      currency: p.currency,
      status: p.status as AdminPaymentStatus,
      yapilyPaymentId: p.yapilyPaymentId,
      initiatedAt: p.initiatedAt.toISOString(),
      completedAt: p.completedAt?.toISOString() ?? null,
    }));

    const recentPaymentLinks: AdminPaymentLinkListItem[] = recentLinksRaw.map((l) => ({
      id: l.id,
      shortCode: l.shortCode,
      payeeName: user.displayName ?? user.email,
      payeeUserId: l.payeeUserId,
      amountCents: l.amountCents,
      currency: l.currency,
      description: l.description,
      status: l.status,
      linkType: l.linkType,
      useCount: l.useCount,
      maxUses: l.maxUses,
      expiresAt: l.expiresAt?.toISOString() ?? null,
      createdAt: l.createdAt.toISOString(),
    }));

    const hostCircles: AdminUserCircleSummary[] = circlesAsHost.map((c) => ({
      id: c.id,
      name: c.name,
      status: c.status,
      role: 'host',
      payoutOrder: null,
    }));

    const memberCircleIds = new Set(circlesAsHost.map((c) => c.id));
    const memberCircles: AdminUserCircleSummary[] = memberships
      .filter((m) => !memberCircleIds.has(m.circle.id))
      .map((m) => ({
        id: m.circle.id,
        name: m.circle.name,
        status: m.circle.status,
        role: 'member',
        payoutOrder: m.payoutOrder,
      }));

    const circles = [...hostCircles, ...memberCircles];

    const mappedAdminState: AdminUserStateDto | null = adminState
      ? {
          status: adminState.status,
          kycTier: adminState.kycTier,
          kycStatus: adminState.kycStatus,
          riskLevel: adminState.riskLevel,
          note: adminState.note,
          frozenReason: adminState.frozenReason,
          updatedByEmail: adminState.updatedByEmail,
          updatedAt: adminState.updatedAt.toISOString(),
        }
      : null;

    const auditEvents: AuditEventDto[] = auditEventsRaw.map((e) => ({
      id: e.id,
      adminEmail: e.adminEmail,
      action: e.action,
      targetType: e.targetType,
      targetId: e.targetId,
      before: e.before,
      after: e.after,
      ip: e.ip,
      createdAt: e.createdAt.toISOString(),
    }));

    const devices: AdminUserDevice[] = user.deviceTokens.map((d) => ({
      id: d.id,
      platform: d.platform,
      lastUpdatedAt: d.updatedAt.toISOString(),
    }));

    return {
      id: user.id,
      email: user.email,
      displayName: user.displayName,
      phoneE164: user.phoneE164,
      phoneVerified: user.phoneVerifiedAt !== null,
      bankVerified: user.bankAccounts.some((b) => b.verified),
      kycStatus: adminState?.kycStatus ?? 'PENDING',
      kycTier: adminState?.kycTier ?? null,
      riskLevel: adminState?.riskLevel ?? 'LOW',
      status: adminState?.status ?? 'ACTIVE',
      lifetimeVolumeCents: volumeAgg._sum.amountCents ?? 0,
      createdAt: user.createdAt.toISOString(),
      lastLoginAt: user.lastLoginAt?.toISOString() ?? null,
      lastSeenAt: user.lastSeenAt?.toISOString() ?? null,
      presence: computePresence(user.lastLoginAt, user.lastSeenAt),
      registeredDeviceCount: user.deviceTokens.length,
      isDeleted: user.deletedAt !== null,
      paymentCount,
      paymentLinkCount,
      bankAccounts,
      recentPayments,
      recentPaymentLinks,
      circles,
      adminState: mappedAdminState,
      auditEvents,
      devices,
    };
  }
}

