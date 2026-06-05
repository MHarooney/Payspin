import { fetchPaymentLink, formatAmount } from '@/lib/api';
import WebShell from '../../components/WebShell';

export default async function SuccessPage({
  params,
}: {
  params: Promise<{ code: string }>;
}) {
  const { code } = await params;

  let detail: string | null = null;
  try {
    const link = await fetchPaymentLink(code);
    const amount =
      link.amountCents != null
        ? formatAmount(link.amountCents, link.currency)
        : null;
    detail =
      amount != null
        ? `${amount} to ${link.payeeDisplayName}`
        : `Sent to ${link.payeeDisplayName}`;
  } catch {
    // Link lookup is best-effort on the success page — never block the
    // confirmation if the link has since settled or the API hiccups.
    detail = null;
  }

  return (
    <WebShell showFooter={false}>
      <div className="ps-card">
        <div className="ps-card__body">
          <div className="ps-status">
            <div className="ps-status__icon ps-status__icon--success" aria-hidden>
              ✓
            </div>
            <h1 className="ps-status__title">Payment sent!</h1>
            {detail && <p className="ps-status__sub">{detail}</p>}
            <p className="ps-status__sub">
              Thank you for using Payspin. You can safely close this page.
            </p>
          </div>
        </div>
      </div>
    </WebShell>
  );
}
