import { Injectable, NotFoundException } from '@nestjs/common';
import { PaymentStatus as PrismaPaymentStatus } from '@prisma/client';
import { abandonPaymentSchema } from '@payspin/validators';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { GetPaymentLinkByShortCodeUseCase } from '../payment-links/get-payment-link-by-short-code.use-case';

@Injectable()
export class AbandonPayerPaymentUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly getLink: GetPaymentLinkByShortCodeUseCase,
  ) {}

  /** Payer declined at the bank or closed the flow before Yapily payment creation. */
  async execute(shortCode: string, body: unknown): Promise<{ status: string }> {
    const parsed = abandonPaymentSchema.parse(body);
    const link = await this.getLink.findOrThrow(shortCode);

    const payment = await this.prisma.payment.findFirst({
      where: {
        id: parsed.paymentId,
        paymentLinkId: link.id,
        status: PrismaPaymentStatus.AWAITING_AUTHORIZATION,
      },
    });
    if (!payment) {
      throw new NotFoundException('Payment not found or already submitted');
    }

    await this.prisma.payment.update({
      where: { id: payment.id },
      data: { status: PrismaPaymentStatus.CANCELLED },
    });

    return { status: PrismaPaymentStatus.CANCELLED };
  }
}
