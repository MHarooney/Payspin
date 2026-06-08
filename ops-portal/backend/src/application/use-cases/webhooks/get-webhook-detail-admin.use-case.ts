import { Injectable, NotFoundException } from '@nestjs/common';
import { AdminWebhookDetail } from '@payspin/shared-types';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { AuditService } from '../../../infrastructure/audit/audit.service';
import { AuditAction } from '../../../domain/constants';
import { AdminRequestContext } from '../../../interfaces/http/decorators/current-admin.decorator';
import { REDACTED_FIELDS } from '../../../interfaces/http/data/data.allowlist';

@Injectable()
export class GetWebhookDetailAdminUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
  ) {}

  async execute(id: string, ctx: AdminRequestContext): Promise<AdminWebhookDetail> {
    const event = await this.prisma.webhookEvent.findUnique({ where: { id } });
    if (!event) throw new NotFoundException('Webhook event not found');

    // Find linked payment by looking up yapilyPaymentId in payments table
    const payload = event.payload as Record<string, unknown>;
    const yapilyId = (payload?.id ?? payload?.paymentId) as string | undefined;
    let linkedPaymentId: string | null = null;
    if (yapilyId) {
      const payment = await this.prisma.payment.findUnique({ where: { yapilyPaymentId: yapilyId } }).catch(() => null);
      linkedPaymentId = payment?.id ?? null;
    }

    // Redact sensitive keys from payload summary
    const payloadSummary: Record<string, unknown> = {};
    for (const [k, v] of Object.entries(payload)) {
      payloadSummary[k] = REDACTED_FIELDS.has(k) ? '***REDACTED***' : v;
    }

    await this.audit.record(
      { adminUserId: ctx.adminUserId, adminEmail: ctx.email, ip: ctx.ip, userAgent: ctx.userAgent },
      { action: AuditAction.WEBHOOK_VIEW, targetType: 'webhook', targetId: id },
    );

    return {
      id: event.id,
      eventId: event.eventId,
      eventType: event.eventType,
      processedAt: event.processedAt?.toISOString() ?? null,
      linkedPaymentId,
      createdAt: event.createdAt.toISOString(),
      payloadSummary,
    };
  }
}
