import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { AdminPaymentLinkDetail, AdminPaymentStatus } from '@payspin/shared-types';
import { patchPaymentLinkAdminSchema } from '@payspin/validators';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { AuditService } from '../../../infrastructure/audit/audit.service';
import { AuditAction } from '../../../domain/constants';
import { AdminRequestContext } from '../../../interfaces/http/decorators/current-admin.decorator';

@Injectable()
export class GetPaymentLinkDetailAdminUseCase {
  constructor(private readonly prisma: PrismaService) {}

  async execute(id: string): Promise<AdminPaymentLinkDetail> {
    const link = await this.prisma.paymentLink.findUnique({
      where: { id },
      include: {
        payeeUser: { select: { displayName: true, email: true } },
        payments: { orderBy: { initiatedAt: 'desc' }, take: 20 },
      },
    });
    if (!link) throw new NotFoundException('Payment link not found');

    return {
      id: link.id,
      shortCode: link.shortCode,
      payeeName: link.payeeUser.displayName ?? link.payeeUser.email,
      payeeUserId: link.payeeUserId,
      amountCents: link.amountCents,
      currency: link.currency,
      description: link.description,
      status: link.status,
      linkType: link.linkType,
      useCount: link.useCount,
      maxUses: link.maxUses,
      expiresAt: link.expiresAt?.toISOString() ?? null,
      createdAt: link.createdAt.toISOString(),
      payments: link.payments.map((p) => ({
        id: p.id,
        shortCode: link.shortCode,
        payeeName: link.payeeUser.displayName ?? link.payeeUser.email,
        payerBankName: p.payerBankName,
        amountCents: p.amountCents,
        currency: p.currency,
        status: p.status as AdminPaymentStatus,
        yapilyPaymentId: p.yapilyPaymentId,
        initiatedAt: p.initiatedAt.toISOString(),
        completedAt: p.completedAt?.toISOString() ?? null,
      })),
    };
  }
}

@Injectable()
export class PatchPaymentLinkAdminUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
  ) {}

  async execute(id: string, body: unknown, ctx: AdminRequestContext): Promise<{ id: string; status: string }> {
    const input = patchPaymentLinkAdminSchema.parse(body);
    const link = await this.prisma.paymentLink.findUnique({ where: { id } });
    if (!link) throw new NotFoundException('Payment link not found');

    if (input.action === 'cancel') {
      if (link.status === 'CANCELLED' || link.status === 'SETTLED') {
        throw new BadRequestException(`Cannot cancel a link with status ${link.status}`);
      }
      const updated = await this.prisma.paymentLink.update({
        where: { id },
        data: { status: 'CANCELLED' },
      });
      await this.audit.record(
        { adminUserId: ctx.adminUserId, adminEmail: ctx.email, ip: ctx.ip, userAgent: ctx.userAgent },
        { action: AuditAction.PAYMENT_LINK_CANCEL, targetType: 'payment_link', targetId: id, before: { status: link.status }, after: { status: 'CANCELLED' } },
      );
      return { id, status: updated.status };
    }

    if (input.action === 'extend') {
      const newExpiry = new Date(input.expiresAt!);
      if (newExpiry <= new Date()) {
        throw new BadRequestException('expiresAt must be in the future');
      }
      const newStatus = link.status === 'EXPIRED' ? 'ACTIVE' : link.status;
      const updated = await this.prisma.paymentLink.update({
        where: { id },
        data: { expiresAt: newExpiry, status: newStatus },
      });
      await this.audit.record(
        { adminUserId: ctx.adminUserId, adminEmail: ctx.email, ip: ctx.ip, userAgent: ctx.userAgent },
        { action: AuditAction.PAYMENT_LINK_EXTEND, targetType: 'payment_link', targetId: id, before: { expiresAt: link.expiresAt }, after: { expiresAt: newExpiry, status: newStatus } },
      );
      return { id, status: updated.status };
    }

    throw new BadRequestException('Unknown action');
  }
}
