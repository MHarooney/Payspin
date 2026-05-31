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
import {
  isSandboxAutoSettleEnabled,
  resolveSandboxPaymentStatus,
} from '../../../domain/utils/sandbox-settlement';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { GetDecryptedIbanUseCase } from '../bank-accounts/get-decrypted-iban.use-case';
import { GetPaymentLinkByShortCodeUseCase } from '../payment-links/get-payment-link-by-short-code.use-case';
import { NotifyPaymentReceivedUseCase } from '../notifications/notify-payment-received.use-case';

const IN_FLIGHT: PrismaPaymentStatus[] = [
  PrismaPaymentStatus.AWAITING_AUTHORIZATION,
  PrismaPaymentStatus.PENDING,
  PrismaPaymentStatus.PROCESSING,
];

@Injectable()
export class CompletePayerPaymentUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly getLink: GetPaymentLinkByShortCodeUseCase,
    private readonly getDecryptedIban: GetDecryptedIbanUseCase,
    @Inject(PIS_GATEWAY) private readonly pisGateway: PisGateway,
    private readonly notifyPaymentReceived: NotifyPaymentReceivedUseCase,
  ) {}

  async execute(shortCode: string, body: unknown): Promise<PaymentPublicStatus> {
    const parsed = completePaymentSchema.parse(body);
    const link = await this.getLink.execute(shortCode);
    const payment = await this.prisma.payment.findFirst({
      where: {
        id: parsed.paymentId,
        paymentLinkId: link.id,
        status: { in: IN_FLIGHT },
      },
    });
    if (!payment) {
      throw new NotFoundException('Payment not found or already completed');
    }

    const consentToken =
      parsed.consentToken ??
      payment.yapilyConsentToken ??
      (process.env.NODE_ENV === 'production' ? undefined : 'sandbox-consent');
    if (!consentToken) {
      throw new BadRequestException('Consent token is required');
    }

    // Callback refresh: payment already submitted to Yapily — poll details only.
    if (
      payment.yapilyPaymentId &&
      payment.status !== PrismaPaymentStatus.AWAITING_AUTHORIZATION
    ) {
      return this.reconcileExisting(link, payment, consentToken);
    }

    if (!payment.idempotencyKey) {
      throw new BadRequestException('Payment is missing initiation data');
    }

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

    const status = await this.resolveRemoteStatus(
      result.paymentId,
      consentToken,
      result.status,
    );

    const updated = await this.applySettlement({
      link,
      paymentId: payment.id,
      fromStatuses: [PrismaPaymentStatus.AWAITING_AUTHORIZATION],
      yapilyPaymentId: result.paymentId,
      yapilyConsentToken: consentToken,
      status,
    });

    return this.toPublic(updated.row);
  }

  private async reconcileExisting(
    link: Awaited<ReturnType<GetPaymentLinkByShortCodeUseCase['execute']>>,
    payment: {
      id: string;
      amountCents: number;
      currency: string;
      yapilyPaymentId: string | null;
    },
    consentToken: string,
  ): Promise<PaymentPublicStatus> {
    if (!payment.yapilyPaymentId) {
      throw new BadRequestException('Payment is missing Yapily reference');
    }

    const remote = await this.fetchRemoteStatus(payment.yapilyPaymentId, consentToken);
    const status = this.toPrismaStatus(remote);

    const updated = await this.applySettlement({
      link,
      paymentId: payment.id,
      fromStatuses: [PrismaPaymentStatus.PENDING, PrismaPaymentStatus.PROCESSING],
      yapilyPaymentId: payment.yapilyPaymentId,
      yapilyConsentToken: consentToken,
      status,
    });

    return this.toPublic(updated.row);
  }

  private async resolveRemoteStatus(
    yapilyPaymentId: string,
    consentToken: string,
    initial: PaymentStatus,
  ): Promise<PrismaPaymentStatus> {
    let status = this.toPrismaStatus(initial);
    if (
      status === PrismaPaymentStatus.PENDING ||
      status === PrismaPaymentStatus.PROCESSING
    ) {
      status = this.toPrismaStatus(
        await this.fetchRemoteStatus(yapilyPaymentId, consentToken),
      );
    }
    return status;
  }

  private async fetchRemoteStatus(
    yapilyPaymentId: string,
    consentToken: string,
  ): Promise<PaymentStatus> {
    try {
      const remote = await this.pisGateway.getPaymentStatus(yapilyPaymentId, consentToken);
      return resolveSandboxPaymentStatus(remote, {
        autoSettle: isSandboxAutoSettleEnabled(),
        submittedToYapily: true,
      });
    } catch {
      return PaymentStatus.PENDING;
    }
  }

  private toPrismaStatus(status: PaymentStatus): PrismaPaymentStatus {
    if (status === PaymentStatus.COMPLETED) return PrismaPaymentStatus.COMPLETED;
    if (status === PaymentStatus.FAILED) return PrismaPaymentStatus.FAILED;
    if (status === PaymentStatus.PROCESSING) return PrismaPaymentStatus.PROCESSING;
    return PrismaPaymentStatus.PENDING;
  }

  private async applySettlement(params: {
    link: Awaited<ReturnType<GetPaymentLinkByShortCodeUseCase['execute']>>;
    paymentId: string;
    fromStatuses: PrismaPaymentStatus[];
    yapilyPaymentId: string;
    yapilyConsentToken: string;
    status: PrismaPaymentStatus;
  }) {
    const { link, paymentId, fromStatuses, yapilyPaymentId, yapilyConsentToken, status } =
      params;
    const terminal =
      status === PrismaPaymentStatus.COMPLETED || status === PrismaPaymentStatus.FAILED;

    const updated = await this.prisma.$transaction(async (tx) => {
      const transition = await tx.payment.updateMany({
        where: {
          id: paymentId,
          status: { in: fromStatuses },
        },
        data: {
          yapilyPaymentId,
          yapilyConsentToken: terminal ? null : yapilyConsentToken,
          status,
          completedAt: status === PrismaPaymentStatus.COMPLETED ? new Date() : null,
        },
      });

      let didComplete = false;
      if (transition.count === 1 && status === PrismaPaymentStatus.COMPLETED) {
        await tx.paymentLink.update({
          where: { id: link.id },
          data: {
            useCount: { increment: 1 },
            status: nextStatusAfterPayment(link),
          },
        });
        didComplete = true;
      }

      const row = await tx.payment.findUniqueOrThrow({ where: { id: paymentId } });
      return { row, didComplete };
    });

    if (updated.didComplete) {
      await this.notifyPaymentReceived.execute({
        payeeUserId: link.payeeUserId,
        paymentId,
        linkId: link.id,
        amountCents: updated.row.amountCents,
        currency: updated.row.currency,
      });
    }

    return updated;
  }

  private toPublic(row: {
    status: PrismaPaymentStatus;
    amountCents: number;
    currency: string;
    completedAt: Date | null;
  }): PaymentPublicStatus {
    return {
      status: row.status as PaymentStatus,
      amountCents: row.amountCents,
      currency: row.currency,
      completedAt: row.completedAt?.toISOString() ?? null,
    };
  }
}
