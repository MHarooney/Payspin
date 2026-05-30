import {
  BadRequestException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PaymentStatus as PrismaPaymentStatus } from '@prisma/client';
import { PaymentPublicStatus, PaymentStatus } from '@payspin/shared-types';
import { completePaymentSchema } from '@payspin/validators';
import { PIS_GATEWAY, PisGateway } from '@payspin/pisp-provider';
import { buildPaymentRequest } from '../../../infrastructure/yapily/payment-request.factory';
import { nextStatusAfterPayment } from '../../../domain/utils/payment-link-state';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { GetDecryptedIbanUseCase } from '../bank-accounts/get-decrypted-iban.use-case';
import { GetPaymentLinkByShortCodeUseCase } from '../payment-links/get-payment-link-by-short-code.use-case';

@Injectable()
export class CompletePayerPaymentUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly getLink: GetPaymentLinkByShortCodeUseCase,
    private readonly getDecryptedIban: GetDecryptedIbanUseCase,
    @Inject(PIS_GATEWAY) private readonly pisGateway: PisGateway,
  ) {}

  async execute(shortCode: string, body: unknown): Promise<PaymentPublicStatus> {
    const parsed = completePaymentSchema.parse(body);
    const link = await this.getLink.execute(shortCode);
    const payment = await this.prisma.payment.findFirst({
      where: {
        id: parsed.paymentId,
        paymentLinkId: link.id,
        status: PrismaPaymentStatus.AWAITING_AUTHORIZATION,
      },
    });
    if (!payment) {
      throw new NotFoundException('Payment not found or already completed');
    }
    if (!payment.idempotencyKey) {
      throw new BadRequestException('Payment is missing initiation data');
    }

    // Fail closed in production: a real bank consent token is mandatory.
    const consentToken =
      parsed.consentToken ??
      (process.env.NODE_ENV === 'production' ? undefined : 'sandbox-consent');
    if (!consentToken) {
      throw new BadRequestException('Consent token is required');
    }

    // Rebuild the payment request from the encrypted IBAN rather than a stored
    // plaintext snapshot.
    const iban = await this.getDecryptedIban.execute(
      link.bankAccountId,
      link.payeeUserId,
    );
    const paymentRequest = buildPaymentRequest({
      amountCents: payment.amountCents,
      currency: payment.currency,
      beneficiaryIban: iban,
      beneficiaryName: link.bankAccount.accountHolder,
      reference: link.description ?? `Payspin ${link.shortCode}`,
      idempotencyKey: payment.idempotencyKey,
    });

    const result = await this.pisGateway.createPayment({
      consentToken,
      paymentRequest,
      idempotencyKey: payment.idempotencyKey,
    });

    const status =
      result.status === PaymentStatus.COMPLETED
        ? PrismaPaymentStatus.COMPLETED
        : result.status === PaymentStatus.FAILED
          ? PrismaPaymentStatus.FAILED
          : PrismaPaymentStatus.PENDING;

    const updated = await this.prisma.$transaction(async (tx) => {
      // Conditional transition: only the request that flips the payment out of
      // AWAITING_AUTHORIZATION increments the link usage. Guards against the
      // callback + webhook double-completion race.
      const transition = await tx.payment.updateMany({
        where: {
          id: payment.id,
          status: PrismaPaymentStatus.AWAITING_AUTHORIZATION,
        },
        data: {
          yapilyPaymentId: result.paymentId,
          status,
          completedAt:
            status === PrismaPaymentStatus.COMPLETED ? new Date() : null,
        },
      });

      if (transition.count === 1 && status === PrismaPaymentStatus.COMPLETED) {
        await tx.paymentLink.update({
          where: { id: link.id },
          data: {
            useCount: { increment: 1 },
            status: nextStatusAfterPayment(link),
          },
        });
      }

      return tx.payment.findUniqueOrThrow({ where: { id: payment.id } });
    });

    return {
      status: updated.status as PaymentStatus,
      amountCents: updated.amountCents,
      currency: updated.currency,
      completedAt: updated.completedAt?.toISOString() ?? null,
    };
  }
}
