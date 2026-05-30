import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PaymentLinkStatus } from '@prisma/client';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';

@Injectable()
export class GetPaymentLinkByShortCodeUseCase {
  constructor(private readonly prisma: PrismaService) {}

  async execute(shortCode: string) {
    const link = await this.prisma.paymentLink.findUnique({
      where: { shortCode },
      include: { payeeUser: true, bankAccount: true },
    });
    if (!link) throw new NotFoundException('Payment link not found');
    if (link.status !== PaymentLinkStatus.ACTIVE) {
      throw new BadRequestException('Payment link is not active');
    }
    if (link.expiresAt && link.expiresAt < new Date()) {
      await this.prisma.paymentLink.update({
        where: { id: link.id },
        data: { status: PaymentLinkStatus.EXPIRED },
      });
      throw new BadRequestException('Payment link has expired');
    }
    return link;
  }
}
