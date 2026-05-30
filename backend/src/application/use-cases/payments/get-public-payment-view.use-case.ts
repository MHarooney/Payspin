import { Injectable } from '@nestjs/common';
import { PublicPaymentLinkView } from '@payspin/shared-types';
import { GetPaymentLinkByShortCodeUseCase } from '../payment-links/get-payment-link-by-short-code.use-case';

@Injectable()
export class GetPublicPaymentViewUseCase {
  constructor(private readonly getLink: GetPaymentLinkByShortCodeUseCase) {}

  async execute(shortCode: string): Promise<PublicPaymentLinkView> {
    const link = await this.getLink.execute(shortCode);
    return {
      shortCode: link.shortCode,
      amountCents: link.amountCents,
      currency: link.currency,
      description: link.description,
      payeeDisplayName: link.payeeUser.displayName ?? link.payeeUser.email,
      status: link.status as PublicPaymentLinkView['status'],
      expiresAt: link.expiresAt?.toISOString() ?? null,
    };
  }
}
