import { Injectable } from '@nestjs/common';
import { CircleSummary } from '@payspin/shared-types';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { countActiveMembers } from './circles-access';
import { CirclesMapper } from './circles.mapper';

@Injectable()
export class ListCirclesUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly mapper: CirclesMapper,
  ) {}

  async execute(userId: string): Promise<CircleSummary[]> {
    const circles = await this.prisma.circle.findMany({
      where: {
        OR: [
          { hostUserId: userId },
          { members: { some: { userId, status: 'ACTIVE' } } },
        ],
      },
      orderBy: { createdAt: 'desc' },
    });

    return Promise.all(
      circles.map(async (circle) => {
        const activeCount = await countActiveMembers(this.prisma, circle.id);
        return this.mapper.toSummary(circle, userId, activeCount);
      }),
    );
  }
}
