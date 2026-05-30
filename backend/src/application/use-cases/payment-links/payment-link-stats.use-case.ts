import { Injectable } from '@nestjs/common';
import { PaymentLinkStatus, PaymentStatus } from '@prisma/client';
import { PaymentLinkSummary } from '@payspin/shared-types';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { PaymentLinksMapper } from './payment-links.mapper';

@Injectable()
export class PaymentLinkStatsUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly mapper: PaymentLinksMapper,
  ) {}

  async withStats(
    linkId: string,
    link: Parameters<PaymentLinksMapper['toSummary']>[0],
  ): Promise<PaymentLinkSummary> {
    const completed = await this.prisma.payment.aggregate({
      where: { paymentLinkId: linkId, status: PaymentStatus.COMPLETED },
      _count: { id: true },
      _sum: { amountCents: true },
    });

    return {
      ...this.mapper.toSummary(link),
      completedPaymentCount: completed._count.id,
      totalReceivedCents: completed._sum.amountCents ?? 0,
    };
  }
}
