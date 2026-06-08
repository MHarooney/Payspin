import { Payment, PaymentStatus as PrismaPaymentStatus } from '@prisma/client';
import { PaymentStatus } from '@payspin/shared-types';
import { nextStatusAfterPayment } from '../../../domain/utils/payment-link-state';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';

export const IN_FLIGHT_PAYMENT_STATUSES: PrismaPaymentStatus[] = [
  PrismaPaymentStatus.AWAITING_AUTHORIZATION,
  PrismaPaymentStatus.PENDING,
  PrismaPaymentStatus.PROCESSING,
];

type PaymentLinkRow = NonNullable<Awaited<ReturnType<PrismaService['paymentLink']['findUnique']>>>;

export type SettlementResult = {
  row: Payment;
  didComplete: boolean;
};

/** Atomically apply a terminal or in-flight status transition and bump link usage on completion. */
export async function applyPaymentSettlement(
  tx: Pick<PrismaService, 'payment' | 'paymentLink'>,
  params: {
    paymentId: string;
    link: PaymentLinkRow;
    fromStatuses: PrismaPaymentStatus[];
    data: {
      status: PrismaPaymentStatus;
      yapilyPaymentId?: string | null;
      yapilyConsentToken?: string | null;
      completedAt?: Date | null;
      webhookRaw?: object;
    };
  },
): Promise<SettlementResult> {
  const { paymentId, link, fromStatuses, data } = params;
  const transition = await tx.payment.updateMany({
    where: { id: paymentId, status: { in: fromStatuses } },
    data,
  });

  let didComplete = false;
  if (transition.count === 1 && data.status === PrismaPaymentStatus.COMPLETED) {
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
}

export function mapYapilyToPrismaStatus(status: PaymentStatus): PrismaPaymentStatus {
  if (status === PaymentStatus.COMPLETED) return PrismaPaymentStatus.COMPLETED;
  if (status === PaymentStatus.FAILED) return PrismaPaymentStatus.FAILED;
  if (status === PaymentStatus.PROCESSING) return PrismaPaymentStatus.PROCESSING;
  return PrismaPaymentStatus.PENDING;
}
