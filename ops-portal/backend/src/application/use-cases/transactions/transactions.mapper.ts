import { Injectable } from '@nestjs/common';
import { AdminPaymentDetail, AdminPaymentListItem, AdminPaymentStatus, AdminWebhookListItem } from '@payspin/shared-types';
import type { Payment, PaymentLink, User } from '@prisma/client';

type PaymentWithLink = Payment & {
  paymentLink: PaymentLink & { payeeUser: Pick<User, 'displayName' | 'email'> };
};

@Injectable()
export class TransactionsMapper {
  toListItem(p: PaymentWithLink): AdminPaymentListItem {
    return {
      id: p.id,
      shortCode: p.paymentLink.shortCode,
      payeeName: p.paymentLink.payeeUser.displayName ?? p.paymentLink.payeeUser.email,
      payerBankName: p.payerBankName,
      amountCents: p.amountCents,
      currency: p.currency,
      status: p.status as AdminPaymentStatus,
      yapilyPaymentId: p.yapilyPaymentId,
      initiatedAt: p.initiatedAt.toISOString(),
      completedAt: p.completedAt?.toISOString() ?? null,
    };
  }

  toDetail(p: PaymentWithLink, relatedWebhooks: AdminWebhookListItem[] = []): AdminPaymentDetail {
    return {
      ...this.toListItem(p),
      paymentLinkId: p.paymentLinkId,
      description: p.paymentLink.description,
      idempotencyKey: p.idempotencyKey,
      yapilyAuthRequestId: p.yapilyAuthRequestId,
      webhookSnapshot: (p.webhookRaw as Record<string, unknown> | null) ?? null,
      relatedWebhooks,
    };
  }
}
