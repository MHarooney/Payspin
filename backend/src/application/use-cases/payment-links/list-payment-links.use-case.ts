import { Injectable } from '@nestjs/common';
import { PaymentLinkSummary } from '@payspin/shared-types';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { PaymentLinkStatsUseCase } from './payment-link-stats.use-case';

@Injectable()
export class ListPaymentLinksUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly stats: PaymentLinkStatsUseCase,
  ) {}

  async execute(userId: string): Promise<PaymentLinkSummary[]> {
    const links = await this.prisma.paymentLink.findMany({
      where: { payeeUserId: userId },
      orderBy: { createdAt: 'desc' },
    });
    return Promise.all(links.map((l) => this.stats.withStats(l.id, l)));
  }
}
