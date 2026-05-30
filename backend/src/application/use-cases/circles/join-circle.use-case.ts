import { BadRequestException, ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { CircleSummary } from '@payspin/shared-types';
import { joinCircleSchema } from '@payspin/validators';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { countActiveMembers } from './circles-access';
import { CirclesMapper } from './circles.mapper';

@Injectable()
export class JoinCircleUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly mapper: CirclesMapper,
  ) {}

  async execute(userId: string, body: unknown): Promise<CircleSummary> {
    const parsed = joinCircleSchema.parse(body);
    const inviteCode = parsed.inviteCode.trim().toLowerCase();

    const circle = await this.prisma.circle.findUnique({
      where: { inviteCode },
    });
    if (!circle) throw new NotFoundException('Invalid invite code');

    if (circle.status !== 'DRAFT') {
      throw new BadRequestException('This circle is no longer accepting members');
    }

    const existing = await this.prisma.circleMember.findUnique({
      where: { circleId_userId: { circleId: circle.id, userId } },
    });
    if (existing?.status === 'ACTIVE') {
      throw new ConflictException('You are already a member of this circle');
    }

    const activeCount = await countActiveMembers(this.prisma, circle.id);
    if (activeCount >= circle.memberCount) {
      throw new ConflictException('This circle is full');
    }

    if (existing) {
      await this.prisma.circleMember.update({
        where: { id: existing.id },
        data: { status: 'ACTIVE', payoutOrder: activeCount },
      });
    } else {
      await this.prisma.circleMember.create({
        data: {
          circleId: circle.id,
          userId,
          payoutOrder: activeCount,
          status: 'ACTIVE',
        },
      });
    }

    const updatedCount = await countActiveMembers(this.prisma, circle.id);
    return this.mapper.toSummary(circle, userId, updatedCount);
  }
}
