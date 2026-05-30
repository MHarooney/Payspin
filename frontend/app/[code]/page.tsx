import { fetchPaymentLink } from '@/lib/api';
import PayButton from './pay-button';

export default async function PaymentPage({
  params,
}: {
  params: Promise<{ code: string }>;
}) {
  const { code } = await params;
  let link;
  try {
    link = await fetchPaymentLink(code);
  } catch {
    return (
      <main style={styles.main}>
        <h1>Link not found</h1>
        <p style={styles.muted}>This payment link may have expired or been cancelled.</p>
      </main>
    );
  }

  const amount =
    link.amountCents != null
      ? `€${(link.amountCents / 100).toFixed(2)}`
      : 'Open amount';

  return (
    <main style={styles.main}>
      <div style={styles.card}>
        <p style={styles.label}>Payspin payment request</p>
        <h1 style={styles.amount}>{amount}</h1>
        <p style={styles.payee}>{link.payeeDisplayName} requests payment</p>
        {link.description && <p style={styles.desc}>{link.description}</p>}
        <PayButton code={code} amountCents={link.amountCents ?? undefined} />
        <p style={styles.footer}>Powered by Yapily open banking · No app install required</p>
      </div>
    </main>
  );
}

const styles: Record<string, React.CSSProperties> = {
  main: { minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 24 },
  card: { background: '#fff', borderRadius: 16, padding: 32, maxWidth: 400, width: '100%', boxShadow: '0 4px 24px rgba(0,0,0,0.08)' },
  label: { fontSize: 12, color: '#9ca3af', textTransform: 'uppercase', letterSpacing: 1 },
  amount: { fontSize: 40, fontWeight: 800, margin: '8px 0', color: '#111827' },
  payee: { color: '#4b5563', marginBottom: 8 },
  desc: { color: '#6b7280', marginBottom: 24 },
  footer: { fontSize: 11, color: '#9ca3af', marginTop: 24, textAlign: 'center' },
  muted: { color: '#6b7280' },
};
