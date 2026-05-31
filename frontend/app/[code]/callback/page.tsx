import { completePayment, fetchPaymentStatus } from '@/lib/api';
import Link from 'next/link';
import CallbackStatusPoller from './CallbackStatusPoller';

export default async function CallbackPage({
  params,
  searchParams,
}: {
  params: Promise<{ code: string }>;
  searchParams: Promise<{
    paymentId?: string;
    consent?: string;
    consentToken?: string;
    sandboxPaymentId?: string;
    error?: string;
  }>;
}) {
  const { code } = await params;
  const query = await searchParams;
  const paymentId = query.paymentId ?? query.sandboxPaymentId;
  const consentToken = query.consent ?? query.consentToken;
  const cancelled = query.error != null;

  // The bank redirected back without authorising (user cancelled / declined).
  if (cancelled) {
    return (
      <Shell>
        <p style={styles.error}>Payment was not completed</p>
        <p style={styles.muted}>You cancelled or your bank declined the authorisation.</p>
        <Link href={`/${code}`} style={styles.link}>
          Try again
        </Link>
      </Shell>
    );
  }

  if (paymentId) {
    try {
      await completePayment(code, paymentId, consentToken);
      const status = await fetchPaymentStatus(code, paymentId);

      if (status.status === 'COMPLETED') {
        return (
          <Shell>
            <p style={styles.success}>Payment sent</p>
            <Link href={`/${code}/success`} style={styles.link}>
              View confirmation
            </Link>
          </Shell>
        );
      }
      if (status.status === 'FAILED' || status.status === 'CANCELLED') {
        return (
          <Shell>
            <p style={styles.error}>Payment failed</p>
            <Link href={`/${code}`} style={styles.link}>
              Back to payment
            </Link>
          </Shell>
        );
      }
      // PENDING / PROCESSING / AWAITING_AUTHORIZATION: the bank is still
      // settling. Webhooks finalise it server-side; the client poller below
      // auto-advances to success without a manual refresh.
      return (
        <Shell>
          <CallbackStatusPoller code={code} paymentId={paymentId} />
        </Shell>
      );
    } catch {
      return (
        <Shell>
          <p style={styles.error}>We couldn’t confirm your payment</p>
          <p style={styles.muted}>
            If money left your account, it is still being processed. Please do
            not pay again — contact the requester if unsure.
          </p>
          <Link href={`/${code}`} style={styles.link}>
            Back to payment
          </Link>
        </Shell>
      );
    }
  }

  return (
    <Shell>
      <p style={styles.muted}>Confirming with your bank…</p>
      <Link href={`/${code}`} style={styles.link}>
        Back to payment
      </Link>
    </Shell>
  );
}

function Shell({ children }: { children: React.ReactNode }) {
  return (
    <main style={styles.main}>
      <div style={styles.card}>{children}</div>
    </main>
  );
}

const styles: Record<string, React.CSSProperties> = {
  main: {
    minHeight: '100vh',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 24,
  },
  card: { background: '#fff', borderRadius: 16, padding: 32, textAlign: 'center', maxWidth: 400 },
  success: { color: '#10b981', fontWeight: 700, fontSize: 20 },
  error: { color: '#ef4444', fontWeight: 700, fontSize: 20 },
  muted: { color: '#6b7280', fontSize: 14, marginTop: 8 },
  link: { color: '#07D8DD', display: 'block', marginTop: 16 },
};
