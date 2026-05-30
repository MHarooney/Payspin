import { BadRequestException, Inject, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PaymentStatus as PrismaPaymentStatus } from '@prisma/client';
import { InitiatePaymentResponse } from '@payspin/shared-types';
import { PIS_GATEWAY, PisGateway } from '@payspin/pisp-provider';
import { randomUUID } from 'crypto';
import { buildPaymentRequest } from '../../../infrastructure/yapily/payment-request.factory';
import { GetDecryptedIbanUseCase } from '../bank-accounts/get-decrypted-iban.use-case';
import { GetPaymentLinkByShortCodeUseCase } from '../payment-links/get-payment-link-by-short-code.use-case';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';

@Injectable()
export class InitiatePayerPaymentUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly getLink: GetPaymentLinkByShortCodeUseCase,
    private readonly getDecryptedIban: GetDecryptedIbanUseCase,
    private readonly config: ConfigService,
    @Inject(PIS_GATEWAY) private readonly pisGateway: PisGateway,
  ) {}

  async execute(shortCode: string, amountCents?: number): Promise<InitiatePaymentResponse> {
    const link = await this.getLink.execute(shortCode);
    const resolvedAmount = link.amountCents ?? amountCents;
    if (!resolvedAmount || resolvedAmount <= 0) {
      throw new BadRequestException('Amount is required for open-amount links');
    }

    const iban = await this.getDecryptedIban.execute(link.bankAccountId, link.payeeUserId);
    const idempotencyKey = randomUUID();
    const payerWebUrl = this.config.get<string>('PAYER_WEB_URL') ?? 'http://localhost:3000';

    const paymentRequest = buildPaymentRequest({
      amountCents: resolvedAmount,
      currency: link.currency,
      beneficiaryIban: iban,
      beneficiaryName: link.bankAccount.accountHolder,
      reference: link.description ?? `Payspin ${link.shortCode}`,
      idempotencyKey,
    });

    const payment = await this.prisma.payment.create({
      data: {
        paymentLinkId: link.id,
        paymentRequestSnapshot: paymentRequest as object,
        amountCents: resolvedAmount,
        currency: link.currency,
        status: PrismaPaymentStatus.AWAITING_AUTHORIZATION,
        idempotencyKey,
      },
    });

    const callbackUrl = `${payerWebUrl}/${shortCode}/callback?paymentId=${payment.id}`;

    const auth = await this.pisGateway.createPaymentAuthRequest({
      applicationUserId: link.payeeUserId,
      callbackUrl,
      paymentRequest,
    });

    await this.prisma.payment.update({
      where: { id: payment.id },
      data: { yapilyAuthRequestId: auth.authRequestId },
    });

    let redirectUrl = auth.authorisationUrl;
    if (auth.authorisationUrl.includes('sandboxPending')) {
      redirectUrl = callbackUrl;
    }

    return {
      paymentId: payment.id,
      redirectUrl,
    };
  }
}
