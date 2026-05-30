import { completePayment, fetchPaymentStatus } from '@/lib/api';
import Link from 'next/link';

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
  }>;
}) {
  const { code } = await params;
  const query = await searchParams;
  const paymentId = query.paymentId ?? query.sandboxPaymentId;
  const consentToken = query.consent ?? query.consentToken;

  if (paymentId) {
    try {
      await completePayment(code, paymentId, consentToken);
      const status = await fetchPaymentStatus(code, paymentId);
      if (status.status === 'COMPLETED') {
        return (
          <main style={styles.main}>
            <div style={styles.card}>
              <p style={styles.success}>Payment sent</p>
              <Link href={`/${code}/success`} style={styles.link}>
                View confirmation
              </Link>
            </div>
          </main>
        );
      }
      if (status.status === 'FAILED') {
        return (
          <main style={styles.main}>
            <div style={styles.card}>
              <p style={styles.error}>Payment failed</p>
              <Link href={`/${code}`} style={styles.link}>
                Back to payment
              </Link>
            </div>
          </main>
        );
      }
    } catch {
      /* fall through */
    }
  }

  return (
    <main style={styles.main}>
      <div style={styles.card}>
        <p>Confirming with your bank…</p>
        <Link href={`/${code}`} style={styles.link}>
          Back to payment
        </Link>
      </div>
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
  card: { background: '#fff', borderRadius: 16, padding: 32, textAlign: 'center' },
  success: { color: '#10b981', fontWeight: 700, fontSize: 20 },
  error: { color: '#ef4444', fontWeight: 700, fontSize: 20 },
  link: { color: '#07D8DD', display: 'block', marginTop: 16 },
};
