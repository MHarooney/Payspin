import { Injectable } from '@nestjs/common';
import { CircleDetail } from '@payspin/shared-types';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { assertParticipant, loadCircleOrThrow, loadDisplayNames } from './circles-access';
import { CirclesMapper } from './circles.mapper';

@Injectable()
export class GetCircleByIdUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly mapper: CirclesMapper,
  ) {}

  async execute(userId: string, circleId: string): Promise<CircleDetail> {
    const circle = await loadCircleOrThrow(this.prisma, circleId);
    await assertParticipant(this.prisma, circleId, userId, circle);

    const members = await this.prisma.circleMember.findMany({
      where: { circleId },
      orderBy: { payoutOrder: 'asc' },
    });

    const displayNames = await loadDisplayNames(
      this.prisma,
      members.map((m) => m.userId),
    );

    return this.mapper.toDetail(circle, userId, members, displayNames);
  }
}
