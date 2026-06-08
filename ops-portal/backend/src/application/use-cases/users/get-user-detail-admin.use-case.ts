import { Injectable, NotFoundException } from '@nestjs/common';
import {
  AdminUserDetail,
  AdminPaymentListItem,
  AdminPaymentStatus,
  AdminUserBankAccount,
  AdminUserCircleSummary,
  AdminUserStateDto,
} from '@payspin/shared-types';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';

@Injectable()
export class GetUserDetailAdminUseCase {
  constructor(private readonly prisma: PrismaService) {}

  async execute(userId: string): Promise<AdminUserDetail> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        bankAccounts: true,
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
      paymentCount,
      paymentLinkCount,
      bankAccounts,
      recentPayments,
      circles,
      adminState: mappedAdminState,
    };
  }
}
