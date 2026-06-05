import { completePayment, fetchPaymentStatus } from '@/lib/api';
import Link from 'next/link';
import WebShell from '../../components/WebShell';
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
      <ResultCard variant="error" title="Payment was not completed">
        <p className="ps-status__sub">
          You cancelled or your bank declined the authorisation.
        </p>
        <Link href={`/${code}`} className="ps-link-btn">
          Try again
        </Link>
      </ResultCard>
    );
  }

  if (paymentId) {
    try {
      await completePayment(code, paymentId, consentToken);
      const status = await fetchPaymentStatus(code, paymentId);

      if (status.status === 'COMPLETED') {
        return (
          <ResultCard variant="success" title="Payment sent">
            <Link href={`/${code}/success`} className="ps-link-btn">
              View confirmation
            </Link>
          </ResultCard>
        );
      }
      if (status.status === 'FAILED' || status.status === 'CANCELLED') {
        return (
          <ResultCard variant="error" title="Payment failed">
            <Link href={`/${code}`} className="ps-link-btn">
              Back to payment
            </Link>
          </ResultCard>
        );
      }
      // PENDING / PROCESSING / AWAITING_AUTHORIZATION: the bank is still
      // settling. Webhooks finalise it server-side; the client poller below
      // auto-advances to success without a manual refresh.
      return (
        <WebShell showFooter={false}>
          <div className="ps-card">
            <div className="ps-card__body">
              <CallbackStatusPoller code={code} paymentId={paymentId} />
            </div>
          </div>
        </WebShell>
      );
    } catch {
      return (
        <ResultCard variant="error" title="We couldn’t confirm your payment">
          <p className="ps-status__sub">
            If money left your account, it is still being processed. Please do
            not pay again — contact the requester if unsure.
          </p>
          <Link href={`/${code}`} className="ps-link-btn">
            Back to payment
          </Link>
        </ResultCard>
      );
    }
  }

  return (
    <WebShell showFooter={false}>
      <div className="ps-card">
        <div className="ps-card__body">
          <div className="ps-status">
            <span className="ps-spinner" aria-hidden />
            <p className="ps-status__sub">Confirming with your bank…</p>
          </div>
          <div style={{ textAlign: 'center' }}>
            <Link href={`/${code}`} className="ps-link-btn">
              Back to payment
            </Link>
          </div>
        </div>
      </div>
    </WebShell>
  );
}

function ResultCard({
  variant,
  title,
  children,
}: {
  variant: 'success' | 'error';
  title: string;
  children: React.ReactNode;
}) {
  return (
    <WebShell showFooter={false}>
      <div className="ps-card">
        <div className="ps-card__body">
          <div className="ps-status">
            <div
              className={`ps-status__icon ps-status__icon--${variant}`}
              aria-hidden
            >
              {variant === 'success' ? '✓' : '!'}
            </div>
            <h1 className="ps-status__title">{title}</h1>
            {children}
          </div>
        </div>
      </div>
    </WebShell>
  );
}
