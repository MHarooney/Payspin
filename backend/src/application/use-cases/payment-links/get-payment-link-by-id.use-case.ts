import { Injectable, NotFoundException } from '@nestjs/common';
import { PaymentLinkDetail } from '@payspin/shared-types';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { PaymentLinkStatsUseCase } from './payment-link-stats.use-case';

@Injectable()
export class GetPaymentLinkByIdUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly stats: PaymentLinkStatsUseCase,
  ) {}

  async execute(userId: string, id: string): Promise<PaymentLinkDetail> {
    const link = await this.prisma.paymentLink.findFirst({
      where: { id, payeeUserId: userId },
    });
    if (!link) throw new NotFoundException('Payment link not found');

    const [summary, payments] = await Promise.all([
      this.stats.withStats(link.id, link),
      this.listPayments(link.id),
    ]);

    return { ...summary, payments };
  }

  private async listPayments(paymentLinkId: string): Promise<PaymentLinkDetail['payments']> {
    const rows = await this.prisma.payment.findMany({
      where: { paymentLinkId },
      orderBy: { initiatedAt: 'desc' },
      take: 50,
    });
    return rows.map((p) => ({
      id: p.id,
      amountCents: p.amountCents,
      currency: p.currency,
      status: p.status as PaymentLinkDetail['payments'][0]['status'],
      payerBankName: p.payerBankName,
      initiatedAt: p.initiatedAt.toISOString(),
      completedAt: p.completedAt?.toISOString() ?? null,
    }));
  }
}
