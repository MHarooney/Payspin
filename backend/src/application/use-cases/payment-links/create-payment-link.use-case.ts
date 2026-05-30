import { Injectable } from '@nestjs/common';
import { PaymentLinkSummary } from '@payspin/shared-types';
import { createPaymentLinkSchema } from '@payspin/validators';
import { generateShortCode } from '../../../domain/utils/short-code';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { GetDefaultBankAccountUseCase } from './get-default-bank-account.use-case';
import { PaymentLinksMapper } from './payment-links.mapper';
import { PaymentLinkStatsUseCase } from './payment-link-stats.use-case';

@Injectable()
export class CreatePaymentLinkUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly getDefaultBankAccount: GetDefaultBankAccountUseCase,
    private readonly mapper: PaymentLinksMapper,
    private readonly stats: PaymentLinkStatsUseCase,
  ) {}

  async execute(userId: string, body: unknown): Promise<PaymentLinkSummary> {
    const parsed = createPaymentLinkSchema.parse(body);
    const bankAccount = await this.getDefaultBankAccount.execute(userId);

    let shortCode = generateShortCode();
    for (let attempt = 0; attempt < 5; attempt++) {
      const existing = await this.prisma.paymentLink.findUnique({ where: { shortCode } });
      if (!existing) break;
      shortCode = generateShortCode();
    }

    const expiresAt = parsed.expiresInDays
      ? new Date(Date.now() + parsed.expiresInDays * 86400000)
      : new Date(Date.now() + 7 * 86400000);

    const link = await this.prisma.paymentLink.create({
      data: {
        shortCode,
        payeeUserId: userId,
        bankAccountId: bankAccount.id,
        amountCents: parsed.amountCents ?? null,
        currency: parsed.currency,
        description: parsed.description ?? null,
        linkType: parsed.linkType,
        maxUses: parsed.maxUses ?? null,
        expiresAt,
      },
    });

    return this.stats.withStats(link.id, link);
  }
}
