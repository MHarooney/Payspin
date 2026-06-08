import { Injectable } from '@nestjs/common';
import { AdminUserListItem, Paginated } from '@payspin/shared-types';
import { listUsersQuerySchema } from '@payspin/validators';
import type { Prisma } from '@prisma/client';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';

@Injectable()
export class ListUsersAdminUseCase {
  constructor(private readonly prisma: PrismaService) {}

  async execute(query: unknown): Promise<Paginated<AdminUserListItem>> {
    const { page, pageSize, status, search } = listUsersQuerySchema.parse(query);

    const where: Prisma.UserWhereInput = {};
    if (search) {
      where.OR = [
        { email: { contains: search, mode: 'insensitive' } },
        { displayName: { contains: search, mode: 'insensitive' } },
        { phoneE164: { contains: search, mode: 'insensitive' } },
      ];
    }

    const [total, users] = await Promise.all([
      this.prisma.user.count({ where }),
      this.prisma.user.findMany({
        where,
        include: { bankAccounts: { select: { verified: true } } },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
    ]);

    const states = await this.prisma.userAdminState.findMany({
      where: { userId: { in: users.map((u) => u.id) } },
    });
    const stateByUser = new Map(states.map((s) => [s.userId, s]));

    const items = await Promise.all(
      users.map(async (u): Promise<AdminUserListItem> => {
        const volume = await this.prisma.payment.aggregate({
          _sum: { amountCents: true },
          where: { status: 'COMPLETED', paymentLink: { payeeUserId: u.id } },
        });
        const state = stateByUser.get(u.id);
        return {
          id: u.id,
          email: u.email,
          displayName: u.displayName,
          phoneE164: u.phoneE164,
          phoneVerified: u.phoneVerifiedAt !== null,
          bankVerified: u.bankAccounts.some((b) => b.verified),
          kycStatus: state?.kycStatus ?? 'PENDING',
          kycTier: state?.kycTier ?? null,
          riskLevel: state?.riskLevel ?? 'LOW',
          status: state?.status ?? 'ACTIVE',
          lifetimeVolumeCents: volume._sum.amountCents ?? 0,
          createdAt: u.createdAt.toISOString(),
        };
      }),
    );

    // Status filter is applied on the admin-overlay status, which may be absent.
    const filtered = status ? items.filter((i) => i.status === status) : items;

    return {
      items: filtered,
      total,
      page,
      pageSize,
      totalPages: Math.max(1, Math.ceil(total / pageSize)),
    };
  }
}
