import {
  BadRequestException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PaymentLinkStatus, PaymentStatus as PrismaPaymentStatus } from '@prisma/client';
import { PaymentPublicStatus, PaymentStatus } from '@payspin/shared-types';
import { PaymentRequestPayload, PIS_GATEWAY, PisGateway } from '@payspin/pisp-provider';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { GetPaymentLinkByShortCodeUseCase } from '../payment-links/get-payment-link-by-short-code.use-case';

@Injectable()
export class CompletePayerPaymentUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly getLink: GetPaymentLinkByShortCodeUseCase,
    @Inject(PIS_GATEWAY) private readonly pisGateway: PisGateway,
  ) {}

  async execute(
    shortCode: string,
    body: { paymentId: string; consentToken?: string },
  ): Promise<PaymentPublicStatus> {
    const link = await this.getLink.execute(shortCode);
    const payment = await this.prisma.payment.findFirst({
      where: {
        id: body.paymentId,
        paymentLinkId: link.id,
        status: PrismaPaymentStatus.AWAITING_AUTHORIZATION,
      },
    });
    if (!payment) {
      throw new NotFoundException('Payment not found or already completed');
    }

    if (!payment.idempotencyKey || !payment.paymentRequestSnapshot) {
      throw new BadRequestException('Payment is missing initiation data');
    }

    const snapshot = payment.paymentRequestSnapshot as unknown as PaymentRequestPayload;
    const consentToken = body.consentToken ?? 'sandbox-consent';

    const result = await this.pisGateway.createPayment({
      consentToken,
      paymentRequest: snapshot,
      idempotencyKey: payment.idempotencyKey,
    });

    const status =
      result.status === PaymentStatus.COMPLETED
        ? PrismaPaymentStatus.COMPLETED
        : result.status === PaymentStatus.FAILED
          ? PrismaPaymentStatus.FAILED
          : PrismaPaymentStatus.PENDING;

    const updated = await this.prisma.$transaction(async (tx) => {
      const p = await tx.payment.update({
        where: { id: payment.id },
        data: {
          yapilyPaymentId: result.paymentId,
          status,
          completedAt: status === PrismaPaymentStatus.COMPLETED ? new Date() : null,
        },
      });

      if (status === PrismaPaymentStatus.COMPLETED) {
        await tx.paymentLink.update({
          where: { id: link.id },
          data: {
            useCount: { increment: 1 },
            status:
              link.linkType === 'SINGLE'
                ? PaymentLinkStatus.SETTLED
                : PaymentLinkStatus.COLLECTING,
          },
        });
      }

      return p;
    });

    return {
      status: updated.status as PaymentStatus,
      amountCents: updated.amountCents,
      currency: updated.currency,
      completedAt: updated.completedAt?.toISOString() ?? null,
    };
  }
}
