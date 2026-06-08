import { Injectable, NotFoundException } from '@nestjs/common';
import { AdminPaymentDetail } from '@payspin/shared-types';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { TransactionsMapper } from './transactions.mapper';

@Injectable()
export class GetPaymentDetailAdminUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly mapper: TransactionsMapper,
  ) {}

  async execute(id: string): Promise<AdminPaymentDetail> {
    const payment = await this.prisma.payment.findUnique({
      where: { id },
      include: { paymentLink: { include: { payeeUser: true } } },
    });
    if (!payment) {
      throw new NotFoundException('Payment not found');
    }

    const relatedWebhooks = payment.yapilyPaymentId
      ? await this.findRelatedWebhooks(payment.yapilyPaymentId)
      : [];

    return this.mapper.toDetail(payment, relatedWebhooks);
  }

  private async findRelatedWebhooks(yapilyPaymentId: string) {
    const events = await this.prisma.webhookEvent.findMany({
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
    return events
      .filter((e) => {
        const p = e.payload as Record<string, unknown>;
        const pid = (p?.['id'] ?? p?.['paymentId']) as string | undefined;
        return pid === yapilyPaymentId;
      })
      .slice(0, 10)
      .map((e) => ({
        id: e.id,
        eventId: e.eventId,
        eventType: e.eventType,
        processedAt: e.processedAt?.toISOString() ?? null,
        linkedPaymentId: yapilyPaymentId,
        createdAt: e.createdAt.toISOString(),
      }));
  }
}
