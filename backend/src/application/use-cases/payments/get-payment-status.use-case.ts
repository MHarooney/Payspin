import { Injectable, NotFoundException } from '@nestjs/common';
import { PaymentPublicStatus, PaymentStatus } from '@payspin/shared-types';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { GetPaymentLinkByShortCodeUseCase } from '../payment-links/get-payment-link-by-short-code.use-case';

@Injectable()
export class GetPaymentStatusUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly getLink: GetPaymentLinkByShortCodeUseCase,
  ) {}

  async execute(shortCode: string, paymentId: string): Promise<PaymentPublicStatus> {
    const link = await this.getLink.execute(shortCode);
    const payment = await this.prisma.payment.findFirst({
      where: {
        paymentLinkId: link.id,
        OR: [{ id: paymentId }, { yapilyPaymentId: paymentId }],
      },
    });
    if (!payment) throw new NotFoundException('Payment not found');

    return {
      status: payment.status as PaymentStatus,
      amountCents: payment.amountCents,
      currency: payment.currency,
      completedAt: payment.completedAt?.toISOString() ?? null,
    };
  }
}
