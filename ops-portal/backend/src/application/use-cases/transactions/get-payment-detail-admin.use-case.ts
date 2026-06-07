import { Injectable, NotFoundException } from '@nestjs/common';
import { AdminPaymentDetail } from '@payspin/shared-types';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { TransactionsMapper } from './transactions.mapper';

@Injectable()
export class GetPaymentDetailAdminUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly mapper: TransactionsMapper,
  ) {}

  async execute(id: string): Promise<AdminPaymentDetail> {
    const payment = await this.prisma.payment.findUnique({
      where: { id },
      include: { paymentLink: { include: { payeeUser: true } } },
    });
    if (!payment) {
      throw new NotFoundException('Payment not found');
    }
    return this.mapper.toDetail(payment);
  }
}
