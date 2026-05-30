import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PaymentLinkStatus } from '@prisma/client';
import { PaymentLinkSummary } from '@payspin/shared-types';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { PaymentLinkStatsUseCase } from './payment-link-stats.use-case';

@Injectable()
export class CancelPaymentLinkUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly stats: PaymentLinkStatsUseCase,
  ) {}

  async execute(userId: string, id: string): Promise<PaymentLinkSummary> {
    const link = await this.prisma.paymentLink.findFirst({
      where: { id, payeeUserId: userId },
    });
    if (!link) throw new NotFoundException('Payment link not found');
    if (link.status !== PaymentLinkStatus.ACTIVE) {
      throw new BadRequestException('Only active links can be cancelled');
    }
    const updated = await this.prisma.paymentLink.update({
      where: { id },
      data: { status: PaymentLinkStatus.CANCELLED },
    });
    return this.stats.withStats(updated.id, updated);
  }
}
