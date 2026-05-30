const API_URL = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3001/v1';

export async function fetchPaymentLink(code: string) {
  const res = await fetch(`${API_URL}/pay/${code}`, { next: { revalidate: 0 } });
  if (!res.ok) throw new Error('Payment link not found');
  return res.json();
}

export async function initiatePayment(code: string, amountCents?: number) {
  const res = await fetch(`${API_URL}/pay/${code}/initiate`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ amountCents }),
  });
  if (!res.ok) throw new Error('Failed to initiate payment');
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
  if (!res.ok) throw new Error('Failed to complete payment');
  return res.json();
}

export async function fetchPaymentStatus(code: string, paymentId: string) {
  const res = await fetch(`${API_URL}/pay/${code}/status/${paymentId}`, {
    cache: 'no-store',
  });
  if (!res.ok) throw new Error('Payment status unavailable');
  return res.json();
}
