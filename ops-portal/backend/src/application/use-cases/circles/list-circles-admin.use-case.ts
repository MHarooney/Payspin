import { Injectable } from '@nestjs/common';
import { AdminCircleListItem, Paginated } from '@payspin/shared-types';
import { listCirclesQuerySchema } from '@payspin/validators';
import type { Prisma } from '@prisma/client';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { CirclesAdminMapper } from './circles-admin.mapper';

@Injectable()
export class ListCirclesAdminUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly mapper: CirclesAdminMapper,
  ) {}

  async execute(query: unknown): Promise<Paginated<AdminCircleListItem>> {
    const { page, pageSize, filter, search } = listCirclesQuerySchema.parse(query);

    const where: Prisma.CircleWhereInput = {};
    if (filter === 'active') {
      where.status = 'ACTIVE';
    } else if (filter === 'completed') {
      where.status = 'COMPLETED';
    }
    if (search) {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { inviteCode: { contains: search, mode: 'insensitive' } },
        { id: { contains: search, mode: 'insensitive' } },
      ];
    }

    const [total, circles] = await Promise.all([
      this.prisma.circle.count({ where }),
      this.prisma.circle.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
    ]);

    let items = await Promise.all(
      circles.map(async (c) => {
        const activeMemberCount = await this.prisma.circleMember.count({
          where: { circleId: c.id, status: 'ACTIVE' },
        });
        return this.mapper.toListItem(c, activeMemberCount);
      }),
    );

    // "At risk" = active circle that is not fully subscribed for the current cycle.
    if (filter === 'risk') {
      items = items.filter(
        (c) => c.status === 'ACTIVE' && c.activeMemberCount < c.memberCount,
      );
    }

    return {
      items,
      total,
      page,
      pageSize,
      totalPages: Math.max(1, Math.ceil(total / pageSize)),
    };
  }
}
