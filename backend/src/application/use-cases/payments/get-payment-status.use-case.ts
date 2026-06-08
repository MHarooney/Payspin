import { Injectable, NotFoundException } from '@nestjs/common';
import { PaymentPublicStatus, PaymentStatus } from '@payspin/shared-types';
import { GetPaymentLinkByShortCodeUseCase } from '../payment-links/get-payment-link-by-short-code.use-case';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { ReconcilePaymentUseCase } from './reconcile-payment.use-case';

@Injectable()
export class GetPaymentStatusUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly getLink: GetPaymentLinkByShortCodeUseCase,
    private readonly reconcile: ReconcilePaymentUseCase,
  ) {}

  async execute(shortCode: string, paymentId: string): Promise<PaymentPublicStatus> {
    const link = await this.getLink.findOrThrow(shortCode);
    const existing = await this.prisma.payment.findFirst({
      where: {
        paymentLinkId: link.id,
        OR: [{ id: paymentId }, { yapilyPaymentId: paymentId }],
      },
    });
    if (!existing) throw new NotFoundException('Payment not found');

    const payment = await this.reconcile.execute(existing.id);

    return {
      status: payment.status as PaymentStatus,
      amountCents: payment.amountCents,
      currency: payment.currency,
      completedAt: payment.completedAt?.toISOString() ?? null,
    };
  }
}
