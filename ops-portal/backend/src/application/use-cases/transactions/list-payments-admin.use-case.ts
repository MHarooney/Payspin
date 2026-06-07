import { Injectable } from '@nestjs/common';
import { AdminPaymentListItem, Paginated } from '@payspin/shared-types';
import { listPaymentsQuerySchema } from '@payspin/validators';
import type { Prisma } from '@prisma/client';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { TransactionsMapper } from './transactions.mapper';

@Injectable()
export class ListPaymentsAdminUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly mapper: TransactionsMapper,
  ) {}

  async execute(query: unknown): Promise<Paginated<AdminPaymentListItem>> {
    const { page, pageSize, status, search } = listPaymentsQuerySchema.parse(query);

    const where: Prisma.PaymentWhereInput = {};
    if (status) {
      where.status = status;
    }
    if (search) {
      where.OR = [
        { yapilyPaymentId: { contains: search, mode: 'insensitive' } },
        { paymentLink: { shortCode: { contains: search, mode: 'insensitive' } } },
        { paymentLink: { payeeUser: { email: { contains: search, mode: 'insensitive' } } } },
      ];
    }

    const [total, rows] = await Promise.all([
      this.prisma.payment.count({ where }),
      this.prisma.payment.findMany({
        where,
        include: { paymentLink: { include: { payeeUser: true } } },
        orderBy: { initiatedAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
    ]);

    return {
      items: rows.map((r) => this.mapper.toListItem(r)),
      total,
      page,
      pageSize,
      totalPages: Math.max(1, Math.ceil(total / pageSize)),
    };
  }
}
