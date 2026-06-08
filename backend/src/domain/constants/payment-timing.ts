/** Minutes before an AWAITING_AUTHORIZATION payment is treated as abandoned. */
export function awaitingAuthorizationStaleMs(env: NodeJS.ProcessEnv = process.env): number {
  const minutes = Number(env.PAYMENT_AWAITING_STALE_MINUTES ?? 60);
  return Math.max(5, minutes) * 60_000;
}

/** Hours before a PENDING/PROCESSING payment with a Yapily ref is marked failed. */
export function pendingPaymentStaleMs(env: NodeJS.ProcessEnv = process.env): number {
  const hours = Number(env.PAYMENT_PENDING_STALE_HOURS ?? 24);
  return Math.max(1, hours) * 3_600_000;
}
