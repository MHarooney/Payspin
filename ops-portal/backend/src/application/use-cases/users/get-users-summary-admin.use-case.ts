import { Injectable } from '@nestjs/common';
import { AdminUsersSummary } from '@payspin/shared-types';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { computePresence } from '../../../domain/presence';

@Injectable()
export class GetUsersSummaryAdminUseCase {
  constructor(private readonly prisma: PrismaService) {}

  async execute(): Promise<AdminUsersSummary> {
    const [total, states, usersPresence] = await Promise.all([
      this.prisma.user.count({ where: { deletedAt: null } }),
      this.prisma.userAdminState.findMany({
        select: { kycStatus: true, status: true },
      }),
      this.prisma.user.findMany({
        where: { deletedAt: null },
        select: { lastLoginAt: true, lastSeenAt: true },
      }),
    ]);

    let online = 0;
    let recent = 0;
    for (const u of usersPresence) {
      const p = computePresence(u.lastLoginAt, u.lastSeenAt);
      if (p === 'online') online++;
      else if (p === 'recent') recent++;
    }

    const pendingKyc = states.filter((s) => s.kycStatus !== 'VERIFIED').length;
    const frozen = states.filter((s) => s.status === 'FROZEN').length;

    return { total, online, recent, pendingKyc, frozen };
  }
}
