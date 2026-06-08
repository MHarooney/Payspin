import {
  BadRequestException,
  ConflictException,
  Inject,
  Injectable,
  Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PaymentLinkType, PaymentStatus as PrismaPaymentStatus } from '@prisma/client';
import { InitiatePaymentResponse } from '@payspin/shared-types';
import { initiatePaymentSchema, validateIbanMod97, normalizeIban } from '@payspin/validators';
import { PIS_GATEWAY, PisGateway } from '@payspin/pisp-provider';
import { randomBytes } from 'crypto';
import {
  buildPaymentRequest,
  redactPaymentRequest,
} from '../../../infrastructure/yapily/payment-request.factory';
import {
  institutionConfigFromEnv,
  resolveInstitutionForIban,
} from '../../../domain/utils/institution-routing';
import { GetDecryptedIbanUseCase } from '../bank-accounts/get-decrypted-iban.use-case';
import { GetPaymentLinkByShortCodeUseCase } from '../payment-links/get-payment-link-by-short-code.use-case';
import { ExpireStalePaymentsUseCase } from '../payments/expire-stale-payments.use-case';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';

@Injectable()
export class InitiatePayerPaymentUseCase {
  private readonly logger = new Logger(InitiatePayerPaymentUseCase.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly getLink: GetPaymentLinkByShortCodeUseCase,
    private readonly getDecryptedIban: GetDecryptedIbanUseCase,
    private readonly expireStale: ExpireStalePaymentsUseCase,
    private readonly config: ConfigService,
    @Inject(PIS_GATEWAY) private readonly pisGateway: PisGateway,
  ) {}

  async execute(shortCode: string, body?: unknown): Promise<InitiatePaymentResponse> {
    const { amountCents, payerMessage } = initiatePaymentSchema.parse(body ?? {});
    const link = await this.getLink.execute(shortCode);

    // Drop abandoned AWAITING rows so SINGLE links are not blocked forever.
    await this.expireStale.execute(link.id);

    // Fixed-amount links ignore any payer-supplied amount.
    const resolvedAmount = link.amountCents ?? amountCents;
    if (!resolvedAmount || resolvedAmount <= 0) {
      throw new BadRequestException('Amount is required for open-amount links');
    }

    const rawIban = await this.getDecryptedIban.execute(link.bankAccountId, link.payeeUserId);
    const iban = normalizeIban(rawIban);

    // Pre-flight IBAN validation: catch invalid IBANs before hitting Yapily
    // to get a clear 400 instead of a 502 YapilyApiError.
    if (!validateIbanMod97(iban)) {
      this.logger.error(
        `Invalid IBAN on bank account ${link.bankAccountId} (last4: ${iban.slice(-4)}) — mod-97 check failed`,
      );
      throw new BadRequestException(
        'The payee bank account has an invalid IBAN. Please ask the payee to re-verify their bank account.',
      );
    }

    // Route to a Yapily institution based on the payee IBAN country (NL/DE/GB/…)
    // instead of always hitting a single hardcoded sandbox.
    const { institutionId } = resolveInstitutionForIban(
      iban,
      institutionConfigFromEnv((key) => this.config.get<string>(key)),
    );
    // Yapily caps paymentIdempotencyId at 35 chars for some institutions (e.g. modelo-sandbox).
    const idempotencyKey = randomBytes(16).toString('hex');
    const payerWebUrl = this.config.get<string>('PAYER_WEB_URL') ?? 'http://localhost:3000';

    const paymentRequest = buildPaymentRequest({
      amountCents: resolvedAmount,
      currency: link.currency,
      beneficiaryIban: iban,
      beneficiaryName: link.bankAccount.accountHolder,
      // Prefer the payer's own note (shows on their bank statement, Tikkie-style);
      // otherwise fall back to the link description, then a stable code.
      reference:
        payerMessage ?? link.description ?? `Payspin ${link.shortCode}`,
      idempotencyKey,
    });

    // Concurrency guard: serialize initiations on this link with a row lock so
    // a SINGLE link can never end up with two in-flight payments (double pay)
    // and a capped MULTI link can never exceed maxUses under concurrent load.
    // The external Yapily call is intentionally kept OUTSIDE this transaction.
    const payment = await this.prisma.$transaction(async (tx) => {
      await tx.$queryRaw`SELECT id FROM payment_links WHERE id = ${link.id} FOR UPDATE`;

      const activeStatuses = [
        PrismaPaymentStatus.AWAITING_AUTHORIZATION,
        PrismaPaymentStatus.PENDING,
        PrismaPaymentStatus.PROCESSING,
        PrismaPaymentStatus.COMPLETED,
      ];

      if (link.linkType === PaymentLinkType.SINGLE) {
        const existing = await tx.payment.findFirst({
          where: { paymentLinkId: link.id, status: { in: activeStatuses } },
        });
        if (existing) {
          throw new ConflictException(
            'This payment link already has a payment in progress',
          );
        }
      } else if (link.maxUses != null) {
        const used = await tx.payment.count({
          where: { paymentLinkId: link.id, status: { in: activeStatuses } },
        });
        if (used >= link.maxUses) {
          throw new ConflictException(
            'This payment link has reached its maximum uses',
          );
        }
      }

      return tx.payment.create({
        data: {
          paymentLinkId: link.id,
          // Persist a redacted snapshot only — the full IBAN is re-derived from
          // the encrypted bank account at completion time, never stored plaintext.
          paymentRequestSnapshot: redactPaymentRequest(paymentRequest) as object,
          amountCents: resolvedAmount,
          currency: link.currency,
          status: PrismaPaymentStatus.AWAITING_AUTHORIZATION,
          idempotencyKey,
        },
      });
    });

    const callbackUrl = `${payerWebUrl}/${shortCode}/callback?paymentId=${payment.id}`;

    const auth = await this.pisGateway.createPaymentAuthRequest({
      applicationUserId: link.payeeUserId,
      institutionId,
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
