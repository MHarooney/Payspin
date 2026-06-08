import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { Payment, PaymentStatus as PrismaPaymentStatus } from '@prisma/client';
import { PaymentStatus } from '@payspin/shared-types';
import { PIS_GATEWAY, PisGateway } from '@payspin/pisp-provider';
import {
  isSandboxAutoSettleEnabled,
  resolveSandboxPaymentStatus,
} from '../../../domain/utils/sandbox-settlement';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { NotifyPaymentReceivedUseCase } from '../notifications/notify-payment-received.use-case';
import { ExpireStalePaymentsUseCase } from './expire-stale-payments.use-case';
import {
  applyPaymentSettlement,
  IN_FLIGHT_PAYMENT_STATUSES,
  mapYapilyToPrismaStatus,
} from './payment-settlement';

@Injectable()
export class ReconcilePaymentUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly expireStale: ExpireStalePaymentsUseCase,
    @Inject(PIS_GATEWAY) private readonly pisGateway: PisGateway,
    private readonly notifyPaymentReceived: NotifyPaymentReceivedUseCase,
  ) {}

  /** Expire stale rows for a link, then reconcile each in-flight payment with Yapily. */
  async reconcileLinkPayments(paymentLinkId: string): Promise<void> {
    await this.expireStale.execute(paymentLinkId);
    const payments = await this.prisma.payment.findMany({
      where: {
        paymentLinkId,
        status: { in: IN_FLIGHT_PAYMENT_STATUSES },
      },
    });
    for (const payment of payments) {
      await this.execute(payment.id).catch(() => undefined);
    }
  }

  /** Expire globally, then reconcile all in-flight payments (background sweep). */
  async reconcileAllInFlight(): Promise<{ expired: number; reconciled: number }> {
    const expired = await this.expireStale.execute();
    const payments = await this.prisma.payment.findMany({
      where: {
        status: {
          in: [
            PrismaPaymentStatus.PENDING,
            PrismaPaymentStatus.PROCESSING,
          ],
        },
        yapilyPaymentId: { not: null },
      },
      take: 100,
      orderBy: { initiatedAt: 'asc' },
    });

    let reconciled = 0;
    for (const payment of payments) {
      const before = payment.status;
      const row = await this.execute(payment.id).catch(() => null);
      if (row && row.status !== before) reconciled += 1;
    }

    return {
      expired: expired.awaitingCancelled + expired.pendingFailed,
      reconciled,
    };
  }

  async execute(paymentId: string): Promise<Payment> {
    const payment = await this.prisma.payment.findUnique({
      where: { id: paymentId },
      include: { paymentLink: true },
    });
    if (!payment) throw new NotFoundException('Payment not found');

    await this.expireStale.execute(payment.paymentLinkId);

    const fresh = await this.prisma.payment.findUniqueOrThrow({
      where: { id: paymentId },
      include: { paymentLink: true },
    });

    if (!IN_FLIGHT_PAYMENT_STATUSES.includes(fresh.status)) {
      return fresh;
    }

    if (
      fresh.status === PrismaPaymentStatus.AWAITING_AUTHORIZATION ||
      !fresh.yapilyPaymentId
    ) {
      return fresh;
    }

    let remote: PaymentStatus;
    try {
      remote = await this.pisGateway.getPaymentStatus(
        fresh.yapilyPaymentId,
        fresh.yapilyConsentToken ?? undefined,
      );
    } catch {
      return fresh;
    }

    remote = resolveSandboxPaymentStatus(remote, {
      autoSettle: isSandboxAutoSettleEnabled(),
      submittedToYapily: true,
    });

    if (remote === PaymentStatus.PENDING || remote === PaymentStatus.PROCESSING) {
      return fresh;
    }

    const prismaStatus = mapYapilyToPrismaStatus(remote);
    const terminal =
      prismaStatus === PrismaPaymentStatus.COMPLETED ||
      prismaStatus === PrismaPaymentStatus.FAILED;

    const updated = await this.prisma.$transaction(async (tx) =>
      applyPaymentSettlement(tx, {
        paymentId: fresh.id,
        link: fresh.paymentLink,
        fromStatuses: [PrismaPaymentStatus.PENDING, PrismaPaymentStatus.PROCESSING],
        data: {
          status: prismaStatus,
          completedAt: prismaStatus === PrismaPaymentStatus.COMPLETED ? new Date() : null,
          yapilyConsentToken: terminal ? null : fresh.yapilyConsentToken,
        },
      }),
    );

    if (updated.didComplete) {
      await this.notifyPaymentReceived.execute({
        payeeUserId: fresh.paymentLink.payeeUserId,
        paymentId: fresh.id,
        linkId: fresh.paymentLinkId,
        amountCents: updated.row.amountCents,
        currency: updated.row.currency,
      });
    }

    return updated.row;
  }
}
