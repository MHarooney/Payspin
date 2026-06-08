import { Injectable, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AdminPaymentDetail } from '@payspin/shared-types';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { AuditService } from '../../../infrastructure/audit/audit.service';
import { AuditAction } from '../../../domain/constants';
import { AdminRequestContext } from '../../../interfaces/http/decorators/current-admin.decorator';
import { TransactionsMapper } from './transactions.mapper';

@Injectable()
export class RefreshPaymentAdminUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly mapper: TransactionsMapper,
    private readonly config: ConfigService,
  ) {}

  async execute(id: string, ctx: AdminRequestContext): Promise<AdminPaymentDetail> {
    const payment = await this.prisma.payment.findUnique({
      where: { id },
      include: { paymentLink: { include: { payeeUser: true } } },
    });
    if (!payment) throw new NotFoundException('Payment not found');

    const before = payment.status;
    await this.callConsumerReconcile(id);

    const refreshed = await this.prisma.payment.findUniqueOrThrow({
      where: { id },
      include: { paymentLink: { include: { payeeUser: true } } },
    });

    await this.audit.record(
      { adminUserId: ctx.adminUserId, adminEmail: ctx.email, ip: ctx.ip, userAgent: ctx.userAgent },
      {
        action: AuditAction.TX_REFRESH,
        targetType: 'payment',
        targetId: id,
        before: { status: before },
        after: { status: refreshed.status },
      },
    );

    return this.mapper.toDetail(refreshed);
  }

  private async callConsumerReconcile(paymentId: string): Promise<void> {
    const base = this.config.get<string>('CONSUMER_API_URL') ?? 'http://localhost:3001/v1';
    const secret = this.config.get<string>('OPS_INTERNAL_SECRET');
    if (!secret) {
      throw new Error('OPS_INTERNAL_SECRET is not configured on the ops backend');
    }

    const res = await fetch(`${base}/internal/payments/${paymentId}/reconcile`, {
      method: 'POST',
      headers: { 'x-ops-internal-secret': secret },
    });

    if (res.status === 404) throw new NotFoundException('Payment not found');
    if (!res.ok) {
      const body = await res.text().catch(() => '');
      throw new Error(`Consumer reconcile failed (${res.status}): ${body}`);
    }
  }
}
