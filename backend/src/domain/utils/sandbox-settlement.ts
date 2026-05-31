import { PaymentStatus } from '@payspin/shared-types';

/**
 * modelo-sandbox (and similar Yapily sandboxes) often leave payments in
 * PENDING with multi-authorisation "offline" — they never reach COMPLETED via
 * polling. While Payspin runs against sandbox institutions, treat a submitted
 * payment as settled once the payer has authorised at the bank.
 */
export function isSandboxAutoSettleEnabled(env: NodeJS.ProcessEnv = process.env): boolean {
  const override = env.PAYSPIN_SANDBOX_AUTO_SETTLE;
  if (override === 'false') return false;
  if (override === 'true') return true;

  const institution = env.YAPILY_DEFAULT_INSTITUTION ?? '';
  return /sandbox|mock/i.test(institution);
}

export function resolveSandboxPaymentStatus(
  remote: PaymentStatus,
  options: { autoSettle: boolean; submittedToYapily: boolean },
): PaymentStatus {
  const { autoSettle, submittedToYapily } = options;
  if (!autoSettle || !submittedToYapily) return remote;

  if (remote === PaymentStatus.PENDING || remote === PaymentStatus.PROCESSING) {
    return PaymentStatus.COMPLETED;
  }
  return remote;
}
