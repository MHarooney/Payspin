import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { Payment, PaymentStatus as PrismaPaymentStatus } from '@prisma/client';
import { PaymentPublicStatus, PaymentStatus } from '@payspin/shared-types';
import { PIS_GATEWAY, PisGateway } from '@payspin/pisp-provider';
import { nextStatusAfterPayment } from '../../../domain/utils/payment-link-state';
import {
  isSandboxAutoSettleEnabled,
  resolveSandboxPaymentStatus,
} from '../../../domain/utils/sandbox-settlement';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { NotifyPaymentReceivedUseCase } from '../notifications/notify-payment-received.use-case';
import { GetPaymentLinkByShortCodeUseCase } from '../payment-links/get-payment-link-by-short-code.use-case';

const IN_FLIGHT: PrismaPaymentStatus[] = [
  PrismaPaymentStatus.PENDING,
  PrismaPaymentStatus.PROCESSING,
];

type PaymentWithLink = Payment & {
  paymentLink: NonNullable<Awaited<ReturnType<PrismaService['paymentLink']['findUnique']>>>;
};

@Injectable()
export class GetPaymentStatusUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly getLink: GetPaymentLinkByShortCodeUseCase,
    @Inject(PIS_GATEWAY) private readonly pisGateway: PisGateway,
    private readonly notifyPaymentReceived: NotifyPaymentReceivedUseCase,
  ) {}

  async execute(shortCode: string, paymentId: string): Promise<PaymentPublicStatus> {
    const link = await this.getLink.findOrThrow(shortCode);
    let payment = await this.prisma.payment.findFirst({
      where: {
        paymentLinkId: link.id,
        OR: [{ id: paymentId }, { yapilyPaymentId: paymentId }],
      },
      include: { paymentLink: true },
    });
    if (!payment) throw new NotFoundException('Payment not found');

    if (payment.yapilyPaymentId && IN_FLIGHT.includes(payment.status)) {
      payment = await this.reconcileWithYapily(payment);
    }

    return {
      status: payment.status as PaymentStatus,
      amountCents: payment.amountCents,
      currency: payment.currency,
      completedAt: payment.completedAt?.toISOString() ?? null,
    };
  }

  /** Best-effort refresh when webhooks are delayed or rate-limited polling blocked updates. */
  private async reconcileWithYapily(payment: PaymentWithLink): Promise<PaymentWithLink> {
    if (!payment.yapilyPaymentId) return payment;

    let remote: PaymentStatus;
    try {
      remote = await this.pisGateway.getPaymentStatus(
        payment.yapilyPaymentId,
        payment.yapilyConsentToken ?? undefined,
      );
    } catch {
      return payment;
    }

    remote = resolveSandboxPaymentStatus(remote, {
      autoSettle: isSandboxAutoSettleEnabled(),
      submittedToYapily: true,
    });

    if (remote === PaymentStatus.PENDING || remote === PaymentStatus.PROCESSING) {
      return payment;
    }

    const isCompleted = remote === PaymentStatus.COMPLETED;
    const prismaStatus = isCompleted
      ? PrismaPaymentStatus.COMPLETED
      : PrismaPaymentStatus.FAILED;

    let didComplete = false;

    const updated = await this.prisma.$transaction(async (tx) => {
      const transition = await tx.payment.updateMany({
        where: {
          id: payment.id,
          status: { in: IN_FLIGHT },
        },
        data: {
          status: prismaStatus,
          completedAt: isCompleted ? new Date() : null,
          yapilyConsentToken:
            isCompleted || remote === PaymentStatus.FAILED ? null : payment.yapilyConsentToken,
        },
      });

      if (transition.count === 1 && isCompleted) {
        await tx.paymentLink.update({
          where: { id: payment.paymentLinkId },
          data: {
            useCount: { increment: 1 },
            status: nextStatusAfterPayment(payment.paymentLink),
          },
        });
        didComplete = true;
      }

      return tx.payment.findUniqueOrThrow({
        where: { id: payment.id },
        include: { paymentLink: true },
      });
    });

    if (didComplete) {
      await this.notifyPaymentReceived.execute({
        payeeUserId: payment.paymentLink.payeeUserId,
        paymentId: payment.id,
        linkId: payment.paymentLinkId,
        amountCents: payment.amountCents,
        currency: payment.currency,
      });
    }

    return updated;
  }
}
