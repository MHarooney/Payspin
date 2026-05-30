import { ConfigService } from '@nestjs/config';
import { PaymentLinkStatus } from '@prisma/client';
import { PaymentLinkSummary } from '@payspin/shared-types';
import { Injectable } from '@nestjs/common';

@Injectable()
export class PaymentLinksMapper {
  constructor(private readonly config: ConfigService) {}

  toSummary(link: {
    id: string;
    shortCode: string;
    amountCents: number | null;
    currency: string;
    description: string | null;
    status: PaymentLinkStatus;
    linkType: string;
    useCount: number;
    maxUses: number | null;
    expiresAt: Date | null;
    createdAt: Date;
  }): PaymentLinkSummary {
    const payerWebUrl = this.config.get<string>('PAYER_WEB_URL') ?? 'http://localhost:3000';
    return {
      id: link.id,
      shortCode: link.shortCode,
      amountCents: link.amountCents,
      currency: link.currency,
      description: link.description,
      status: link.status as PaymentLinkSummary['status'],
      linkType: link.linkType as PaymentLinkSummary['linkType'],
      useCount: link.useCount,
      maxUses: link.maxUses,
      expiresAt: link.expiresAt?.toISOString() ?? null,
      createdAt: link.createdAt.toISOString(),
      payUrl: `${payerWebUrl}/${link.shortCode}`,
      completedPaymentCount: 0,
      totalReceivedCents: 0,
    };
  }
}
