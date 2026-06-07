import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { AdminPaymentDetail } from '@payspin/shared-types';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { AuditService } from '../../../infrastructure/audit/audit.service';
import { AuditAction } from '../../../domain/constants';
import { AdminRequestContext } from '../../../interfaces/http/decorators/current-admin.decorator';
import { TransactionsMapper } from './transactions.mapper';

/**
 * Re-queues a stuck payment by moving it back to PROCESSING so the consumer
 * backend's reconciliation can pick it up. Audit-logged. Only payments that are
 * actually stuck (FAILED / awaiting) can be retried.
 */
@Injectable()
export class RetryPaymentAdminUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly mapper: TransactionsMapper,
  ) {}

  async execute(id: string, ctx: AdminRequestContext): Promise<AdminPaymentDetail> {
    const payment = await this.prisma.payment.findUnique({
      where: { id },
      include: { paymentLink: { include: { payeeUser: true } } },
    });
    if (!payment) {
      throw new NotFoundException('Payment not found');
    }
    if (!['FAILED', 'AWAITING_AUTHORIZATION', 'PENDING'].includes(payment.status)) {
      throw new BadRequestException(`Cannot retry a payment in status ${payment.status}`);
    }

    const updated = await this.prisma.payment.update({
      where: { id },
      data: { status: 'PROCESSING' },
      include: { paymentLink: { include: { payeeUser: true } } },
    });

    await this.audit.record(
      { adminUserId: ctx.adminUserId, adminEmail: ctx.email, ip: ctx.ip, userAgent: ctx.userAgent },
      {
        action: AuditAction.TX_RETRY,
        targetType: 'payment',
        targetId: id,
        before: { status: payment.status },
        after: { status: 'PROCESSING' },
      },
    );

    return this.mapper.toDetail(updated);
  }
}
