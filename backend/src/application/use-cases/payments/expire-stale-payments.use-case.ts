import { Injectable } from '@nestjs/common';
import { PaymentStatus as PrismaPaymentStatus } from '@prisma/client';
import {
  awaitingAuthorizationStaleMs,
  pendingPaymentStaleMs,
} from '../../../domain/constants/payment-timing';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';

@Injectable()
export class ExpireStalePaymentsUseCase {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Marks abandoned pre-Yapily attempts CANCELLED and long-stuck Yapily
   * submissions FAILED so SINGLE links can accept new payers.
   */
  async execute(paymentLinkId?: string): Promise<{ awaitingCancelled: number; pendingFailed: number }> {
    const now = Date.now();
    const linkFilter = paymentLinkId ? { paymentLinkId } : {};

    const awaitingCancelled = await this.prisma.payment.updateMany({
      where: {
        ...linkFilter,
        status: PrismaPaymentStatus.AWAITING_AUTHORIZATION,
        initiatedAt: { lt: new Date(now - awaitingAuthorizationStaleMs()) },
      },
      data: { status: PrismaPaymentStatus.CANCELLED },
    });

    const pendingFailed = await this.prisma.payment.updateMany({
      where: {
        ...linkFilter,
        status: { in: [PrismaPaymentStatus.PENDING, PrismaPaymentStatus.PROCESSING] },
        yapilyPaymentId: { not: null },
        initiatedAt: { lt: new Date(now - pendingPaymentStaleMs()) },
      },
      data: {
        status: PrismaPaymentStatus.FAILED,
        completedAt: null,
        yapilyConsentToken: null,
      },
    });

    return {
      awaitingCancelled: awaitingCancelled.count,
      pendingFailed: pendingFailed.count,
    };
  }
}
