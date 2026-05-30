import { BadRequestException, Injectable } from '@nestjs/common';
import { CircleDetail } from '@payspin/shared-types';
import { updateCircleMemberSchema } from '@payspin/validators';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import {
  assertHost,
  loadCircleOrThrow,
  loadDisplayNames,
} from './circles-access';
import { CirclesMapper } from './circles.mapper';

@Injectable()
export class UpdateCircleMemberUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly mapper: CirclesMapper,
  ) {}

  async execute(
    userId: string,
    circleId: string,
    memberId: string,
    body: unknown,
  ): Promise<CircleDetail> {
    const parsed = updateCircleMemberSchema.parse(body);
    const circle = await loadCircleOrThrow(this.prisma, circleId);
    await assertHost(circle, userId);

    if (circle.status !== 'DRAFT') {
      throw new BadRequestException('Members can only be updated while the circle is in draft');
    }

    const member = await this.prisma.circleMember.findFirst({
      where: { id: memberId, circleId },
    });
    if (!member) throw new BadRequestException('Member not found');

    if (member.userId === circle.hostUserId && parsed.status === 'REMOVED') {
      throw new BadRequestException('The host cannot be removed from the circle');
    }

    await this.prisma.circleMember.update({
      where: { id: memberId },
      data: {
        ...(parsed.payoutOrder !== undefined ? { payoutOrder: parsed.payoutOrder } : {}),
        ...(parsed.status !== undefined ? { status: parsed.status } : {}),
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
    return this.mapper.toDetail(circle, userId, members, displayNames);
  }
}
