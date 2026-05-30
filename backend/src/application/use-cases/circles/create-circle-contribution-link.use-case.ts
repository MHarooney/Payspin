import { BadRequestException, Injectable } from '@nestjs/common';
import { PaymentLinkSummary } from '@payspin/shared-types';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { CreatePaymentLinkUseCase } from '../payment-links/create-payment-link.use-case';
import { assertHost, countActiveMembers, loadCircleOrThrow } from './circles-access';

/**
 * MVP contribution collection: host creates a MULTI payment link for the current
 * round. Members pay via the existing payer web flow; no duplicate Yapily logic.
 */
@Injectable()
export class CreateCircleContributionLinkUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly createLink: CreatePaymentLinkUseCase,
  ) {}

  async execute(userId: string, circleId: string): Promise<PaymentLinkSummary> {
    const circle = await loadCircleOrThrow(this.prisma, circleId);
    await assertHost(circle, userId);

    if (circle.status !== 'ACTIVE') {
      throw new BadRequestException('Contribution links are only available for active circles');
    }

    const activeCount = await countActiveMembers(this.prisma, circleId);

    return this.createLink.execute(userId, {
      amountCents: circle.contributionCents,
      currency: 'EUR',
      description: `${circle.name} — Round ${circle.currentRound + 1}`,
      linkType: 'MULTI',
      maxUses: activeCount,
      expiresInDays: circle.cycleDurationDays,
    });
  }
}
