import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PaymentLinkStatus } from '@prisma/client';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import {
  hasReachedMaxUses,
  isPayableStatus,
} from '../../../domain/utils/payment-link-state';

const LINK_INCLUDE = { payeeUser: true, bankAccount: true } as const;

@Injectable()
export class GetPaymentLinkByShortCodeUseCase {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Resolves a link by short code, lazily flipping it to EXPIRED when past due.
   * Does NOT enforce payability — use for read/status flows that must work
   * after a link is SETTLED/EXPIRED/CANCELLED.
   */
  async findOrThrow(shortCode: string) {
    const link = await this.prisma.paymentLink.findUnique({
      where: { shortCode },
      include: LINK_INCLUDE,
    });
    if (!link) throw new NotFoundException('Payment link not found');

    if (
      link.status !== PaymentLinkStatus.EXPIRED &&
      link.expiresAt &&
      link.expiresAt < new Date()
    ) {
      return this.prisma.paymentLink.update({
        where: { id: link.id },
        data: { status: PaymentLinkStatus.EXPIRED },
        include: LINK_INCLUDE,
      });
    }
    return link;
  }

  /** Resolves a link and asserts it can currently accept a payment. */
  async execute(shortCode: string) {
    const link = await this.findOrThrow(shortCode);
    if (link.status === PaymentLinkStatus.EXPIRED) {
      throw new BadRequestException('Payment link has expired');
    }
    if (!isPayableStatus(link.status)) {
      throw new BadRequestException('Payment link is not active');
    }
    if (hasReachedMaxUses(link)) {
      throw new BadRequestException('Payment link has reached its maximum uses');
    }
    return link;
  }
}
