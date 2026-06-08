import { Injectable, NotFoundException } from '@nestjs/common';
import { AdminCircleDetail } from '@payspin/shared-types';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { CirclesAdminMapper } from './circles-admin.mapper';

@Injectable()
export class GetCircleDetailAdminUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly mapper: CirclesAdminMapper,
  ) {}

  async execute(id: string): Promise<AdminCircleDetail> {
    const circle = await this.prisma.circle.findUnique({
      where: { id },
      include: { members: true },
    });
    if (!circle) {
      throw new NotFoundException('Circle not found');
    }

    const memberUserIds = circle.members.map((m) => m.userId);
    const users = await this.prisma.user.findMany({
      where: { id: { in: [...memberUserIds, circle.hostUserId] } },
      select: { id: true, displayName: true },
    });
    const nameById = new Map(users.map((u) => [u.id, u]));

    const membersWithNames = circle.members.map((m) => ({
      ...m,
      user: nameById.get(m.userId) ?? null,
    }));

    return this.mapper.toDetail(
      circle,
      membersWithNames,
      nameById.get(circle.hostUserId) ?? null,
    );
  }
}
