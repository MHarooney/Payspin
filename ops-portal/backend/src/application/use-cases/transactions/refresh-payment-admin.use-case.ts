import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { AdminPaymentDetail } from '@payspin/shared-types';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { AuditService } from '../../../infrastructure/audit/audit.service';
import { AuditAction } from '../../../domain/constants';
import { AdminRequestContext } from '../../../interfaces/http/decorators/current-admin.decorator';
import { TransactionsMapper } from './transactions.mapper';

/**
 * Refresh: returns the current payment detail from Postgres.
 * Full Yapily status poll requires wiring pisp-provider into ops-portal/backend
 * (currently ops-only infra). The refresh is logged in the audit trail; ops can
 * see the current DB state and manually move status via retry if stuck.
 */
@Injectable()
export class RefreshPaymentAdminUseCase {
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
    if (!payment) throw new NotFoundException('Payment not found');

    if (!payment.yapilyPaymentId) {
      throw new BadRequestException('Cannot refresh: no Yapily payment ID on record');
    }

    await this.audit.record(
      { adminUserId: ctx.adminUserId, adminEmail: ctx.email, ip: ctx.ip, userAgent: ctx.userAgent },
      { action: AuditAction.TX_REFRESH, targetType: 'payment', targetId: id, after: { status: payment.status } },
    );

    return this.mapper.toDetail(payment);
  }
}

