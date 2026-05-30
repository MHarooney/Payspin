import { ApiError, fetchPaymentLink, formatAmount, PaymentLinkView } from '@/lib/api';
import PayButton from './pay-button';

const PAYABLE: PaymentLinkView['status'][] = ['ACTIVE', 'COLLECTING'];

function unavailableMessage(link: PaymentLinkView): string | null {
  const expired =
    link.expiresAt != null && new Date(link.expiresAt).getTime() < Date.now();
  if (link.status === 'SETTLED') {
    return 'This payment request has already been completed.';
  }
  if (link.status === 'CANCELLED') {
    return 'This payment link was cancelled by the requester.';
  }
  if (link.status === 'EXPIRED' || expired) {
    return 'This payment link has expired.';
  }
  if (!PAYABLE.includes(link.status)) {
    return 'This payment link is no longer available.';
  }
  return null;
}

export default async function PaymentPage({
  params,
}: {
  params: Promise<{ code: string }>;
}) {
  const { code } = await params;
  let link: PaymentLinkView;
  try {
    link = await fetchPaymentLink(code);
  } catch (err) {
    const notFound = err instanceof ApiError && err.status === 404;
    return (
      <main style={styles.main}>
        <div style={styles.card}>
          <h1 style={styles.title}>
            {notFound ? 'Link not found' : 'Something went wrong'}
          </h1>
          <p style={styles.muted}>
            {notFound
              ? 'This payment link does not exist. Please check the link and try again.'
              : 'We could not load this payment request. Please try again in a moment.'}
          </p>
        </div>
      </main>
    );
  }

  const openAmount = link.amountCents == null;
  const amountLabel = openAmount
    ? 'Open amount'
    : formatAmount(link.amountCents as number, link.currency);
  const blocked = unavailableMessage(link);

  return (
    <main style={styles.main}>
      <div style={styles.card}>
        <p style={styles.label}>Payspin payment request</p>
        <h1 style={styles.amount}>{amountLabel}</h1>
        <p style={styles.payee}>{link.payeeDisplayName} requests payment</p>
        {link.description && <p style={styles.desc}>{link.description}</p>}

        {blocked ? (
          <div style={styles.notice}>{blocked}</div>
        ) : (
          <PayButton
            code={code}
            amountCents={link.amountCents ?? undefined}
            currency={link.currency}
            openAmount={openAmount}
          />
        )}

        <p style={styles.footer}>
          Powered by Yapily open banking · No app install required
        </p>
      </div>
    </main>
  );
}

const styles: Record<string, React.CSSProperties> = {
  main: { minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 24 },
  card: { background: '#fff', borderRadius: 16, padding: 32, maxWidth: 400, width: '100%', boxShadow: '0 4px 24px rgba(0,0,0,0.08)' },
  label: { fontSize: 12, color: '#9ca3af', textTransform: 'uppercase', letterSpacing: 1 },
  title: { fontSize: 24, fontWeight: 800, color: '#111827' },
  amount: { fontSize: 40, fontWeight: 800, margin: '8px 0', color: '#111827' },
  payee: { color: '#4b5563', marginBottom: 8 },
  desc: { color: '#6b7280', marginBottom: 24 },
  notice: { background: '#f3f4f6', borderRadius: 12, padding: 16, color: '#4b5563', fontSize: 14, textAlign: 'center' },
  footer: { fontSize: 11, color: '#9ca3af', marginTop: 24, textAlign: 'center' },
  muted: { color: '#6b7280' },
};
