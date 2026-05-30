import { BadRequestException, Injectable } from '@nestjs/common';
import { CircleDetail } from '@payspin/shared-types';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import {
  assertHost,
  countActiveMembers,
  loadCircleOrThrow,
  loadDisplayNames,
} from './circles-access';
import { CirclesMapper } from './circles.mapper';

@Injectable()
export class AdvanceCircleRoundUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly mapper: CirclesMapper,
  ) {}

  async execute(userId: string, circleId: string): Promise<CircleDetail> {
    const circle = await loadCircleOrThrow(this.prisma, circleId);
    await assertHost(circle, userId);

    if (circle.status !== 'ACTIVE') {
      throw new BadRequestException('Circle must be active to advance a round');
    }

    const activeCount = await countActiveMembers(this.prisma, circleId);
    const nextRound = circle.currentRound + 1;

    const updated = await this.prisma.circle.update({
      where: { id: circleId },
      data: {
        currentRound: nextRound,
        ...(nextRound >= activeCount ? { status: 'COMPLETED' } : {}),
      },
    });

    const members = await this.prisma.circleMember.findMany({
      where: { circleId },
      orderBy: { payoutOrder: 'asc' },
    });
    const displayNames = await loadDisplayNames(
      this.prisma,
      members.map((m) => m.userId),
    );
    return this.mapper.toDetail(updated, userId, members, displayNames);
  }
}
