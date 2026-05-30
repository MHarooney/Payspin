import { Injectable } from '@nestjs/common';
import { CircleSummary } from '@payspin/shared-types';
import { createCircleSchema } from '@payspin/validators';
import { generateShortCode } from '../../../domain/utils/short-code';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { countActiveMembers } from './circles-access';
import { CirclesMapper } from './circles.mapper';

@Injectable()
export class CreateCircleUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly mapper: CirclesMapper,
  ) {}

  async execute(userId: string, body: unknown): Promise<CircleSummary> {
    const parsed = createCircleSchema.parse(body);

    let inviteCode = generateShortCode(8);
    for (let attempt = 0; attempt < 5; attempt++) {
      const existing = await this.prisma.circle.findUnique({ where: { inviteCode } });
      if (!existing) break;
      inviteCode = generateShortCode(8);
    }

    const circle = await this.prisma.$transaction(async (tx) => {
      const created = await tx.circle.create({
        data: {
          name: parsed.name,
          hostUserId: userId,
          memberCount: parsed.memberCount,
          contributionCents: parsed.contributionCents,
          cycleDurationDays: parsed.cycleDurationDays,
          inviteCode,
          status: 'DRAFT',
          currentRound: 0,
        },
      });
      await tx.circleMember.create({
        data: {
          circleId: created.id,
          userId,
          payoutOrder: 0,
          status: 'ACTIVE',
        },
      });
      return created;
    });

    const activeCount = await countActiveMembers(this.prisma, circle.id);
    return this.mapper.toSummary(circle, userId, activeCount);
  }
}
