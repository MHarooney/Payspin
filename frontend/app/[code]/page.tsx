import { ApiError, fetchPaymentLink, formatAmount, PaymentLinkView } from '@/lib/api';
import WebShell from '../components/WebShell';
import FaqAccordion, { PAYER_FAQ } from '../components/FaqAccordion';
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
      <WebShell>
        <div className="ps-card">
          <div className="ps-card__body">
            <div className="ps-status">
              <div className="ps-status__icon ps-status__icon--error" aria-hidden>
                !
              </div>
              <h1 className="ps-status__title">
                {notFound ? 'Link not found' : 'Something went wrong'}
              </h1>
              <p className="ps-status__sub">
                {notFound
                  ? 'This payment link does not exist. Please check the link and try again.'
                  : 'We could not load this payment request. Please try again in a moment.'}
              </p>
            </div>
          </div>
        </div>
      </WebShell>
    );
  }

  const openAmount = link.amountCents == null;
  const amountLabel = openAmount
    ? 'Open amount'
    : formatAmount(link.amountCents as number, link.currency);
  const blocked = unavailableMessage(link);
  const title = link.description?.trim() || 'Payment request';

  return (
    <WebShell>
      <div className="ps-card">
        <div className="ps-card__band">
          <p className="ps-eyebrow">Payment request</p>
          <h1 className="ps-title">{title}</h1>
          <p className="ps-payee">
            To {link.payeeDisplayName}
            <span className="ps-verified" title="Verified payee" aria-label="Verified payee">
              ✓
            </span>
          </p>
          <p className="ps-amount">{amountLabel}</p>
        </div>

        <div className="ps-card__body">
          {blocked ? (
            <div className="ps-notice">{blocked}</div>
          ) : (
            <PayButton
              code={code}
              amountCents={link.amountCents ?? undefined}
              currency={link.currency}
              payeeName={link.payeeDisplayName}
              openAmount={openAmount}
            />
          )}

          <p className="ps-legal">
            By continuing, you accept the Payspin{' '}
            <a href="https://payspin.io/terms" target="_blank" rel="noreferrer">
              Terms of use
            </a>
            .
          </p>
        </div>
      </div>

      <FaqAccordion items={PAYER_FAQ} />

      <section className="ps-support">
        <h2 className="ps-section-title">Having trouble?</h2>
        <a className="ps-support__btn" href="mailto:support@payspin.io">
          Contact support
        </a>
      </section>
    </WebShell>
  );
}
