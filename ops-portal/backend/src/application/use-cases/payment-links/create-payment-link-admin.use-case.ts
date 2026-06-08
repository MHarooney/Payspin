import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { CreatePaymentLinkAdminResult } from '@payspin/shared-types';
import { createPaymentLinkOpsSchema } from '@payspin/validators';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { AuditService } from '../../../infrastructure/audit/audit.service';
import { AuditAction } from '../../../domain/constants';
import { generateShortCode } from '../../../domain/short-code';
import { AdminRequestContext } from '../../../interfaces/http/decorators/current-admin.decorator';

@Injectable()
export class CreatePaymentLinkAdminUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly config: ConfigService,
  ) {}

  async execute(body: unknown, ctx: AdminRequestContext): Promise<CreatePaymentLinkAdminResult> {
    const input = createPaymentLinkOpsSchema.parse(body);

    const user = await this.prisma.user.findUnique({ where: { id: input.payeeUserId } });
    if (!user || user.deletedAt) {
      throw new NotFoundException('Payee user not found');
    }

    const bankAccount = await this.prisma.bankAccount.findFirst({
      where: { userId: input.payeeUserId },
      orderBy: [{ isPrimary: 'desc' }, { createdAt: 'desc' }],
    });
    if (!bankAccount) {
      throw new BadRequestException('Payee must have a bank account before creating payment links');
    }

    let shortCode = generateShortCode();
    for (let attempt = 0; attempt < 5; attempt++) {
      const existing = await this.prisma.paymentLink.findUnique({ where: { shortCode } });
      if (!existing) break;
      shortCode = generateShortCode();
    }

    const expiresAt = new Date(Date.now() + 7 * 86400000);

    const link = await this.prisma.paymentLink.create({
      data: {
        shortCode,
        payeeUserId: input.payeeUserId,
        bankAccountId: bankAccount.id,
        amountCents: input.amountCents ?? null,
        currency: input.currency ?? 'EUR',
        description: input.description ?? null,
        linkType: 'SINGLE',
        expiresAt,
      },
    });

    const payerBase = (this.config.get<string>('PAYER_WEB_URL') ?? 'http://localhost:3000').replace(/\/$/, '');
    const result: CreatePaymentLinkAdminResult = {
      id: link.id,
      shortCode: link.shortCode,
      payerUrl: `${payerBase}/${link.shortCode}`,
      amountCents: link.amountCents,
      currency: link.currency,
      expiresAt: link.expiresAt!.toISOString(),
      payeeUserId: link.payeeUserId,
    };

    await this.audit.record(
      { adminUserId: ctx.adminUserId, adminEmail: ctx.email, ip: ctx.ip, userAgent: ctx.userAgent },
      {
        action: AuditAction.PAYMENT_LINK_CREATE,
        targetType: 'payment_link',
        targetId: link.id,
        after: { shortCode, payeeUserId: input.payeeUserId, amountCents: input.amountCents },
      },
    );

    return result;
  }
}
