const API_URL = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3001/v1';

export class ApiError extends Error {
  constructor(
    public status: number,
    message: string,
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

/** Best-effort parse of the backend's `{ message, issues[] }` error body. */
async function toApiError(res: Response, fallback: string): Promise<ApiError> {
  try {
    const body = await res.json();
    if (typeof body?.message === 'string' && body.message) {
      return new ApiError(res.status, body.message);
    }
    if (Array.isArray(body?.issues) && body.issues[0]?.message) {
      return new ApiError(res.status, body.issues[0].message as string);
    }
  } catch {
    /* non-JSON body */
  }
  return new ApiError(res.status, fallback);
}

export type PaymentLinkStatus =
  | 'ACTIVE'
  | 'COLLECTING'
  | 'EXPIRED'
  | 'CANCELLED'
  | 'SETTLED';

export interface PaymentLinkView {
  shortCode: string;
  amountCents: number | null;
  currency: string;
  description: string | null;
  payeeDisplayName: string;
  status: PaymentLinkStatus;
  expiresAt: string | null;
}

export async function fetchPaymentLink(code: string): Promise<PaymentLinkView> {
  const res = await fetch(`${API_URL}/pay/${code}`, { next: { revalidate: 0 } });
  if (!res.ok) {
    throw await toApiError(
      res,
      res.status === 404
        ? 'Payment link not found'
        : 'Could not load this payment link',
    );
  }
  return res.json();
}

export async function initiatePayment(
  code: string,
  amountCents?: number,
  payerMessage?: string,
) {
  const res = await fetch(`${API_URL}/pay/${code}/initiate`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ amountCents, payerMessage }),
  });
  if (!res.ok) {
    throw await toApiError(res, 'Could not start the payment. Please try again.');
  }
  return res.json() as Promise<{ paymentId: string; redirectUrl: string }>;
}

export async function completePayment(
  code: string,
  paymentId: string,
  consentToken?: string,
) {
  const res = await fetch(`${API_URL}/pay/${code}/complete`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ paymentId, consentToken }),
  });
  if (!res.ok) {
    throw await toApiError(res, 'Could not confirm the payment with your bank.');
  }
  return res.json();
}

export async function fetchPaymentStatus(code: string, paymentId: string) {
  const res = await fetch(`${API_URL}/pay/${code}/status/${paymentId}`, {
    cache: 'no-store',
  });
  if (!res.ok) throw await toApiError(res, 'Payment status unavailable');
  return res.json() as Promise<{
    status: string;
    amountCents: number;
    currency: string;
    completedAt: string | null;
  }>;
}

/** Localised money formatting with a safe fallback for unknown currencies. */
export function formatAmount(cents: number, currency: string): string {
  try {
    return new Intl.NumberFormat('en-IE', {
      style: 'currency',
      currency,
    }).format(cents / 100);
  } catch {
    return `${currency} ${(cents / 100).toFixed(2)}`;
  }
}
