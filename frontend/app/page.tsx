import WebShell from './components/WebShell';

export default function HomePage() {
  return (
    <WebShell showFooter={false}>
      <div className="ps-card">
        <div className="ps-card__body">
          <div className="ps-status">
            <h1 className="ps-status__title">Payspin Pay</h1>
            <p className="ps-status__sub">
              Open a payment link shared with you, e.g. pay.payspin.io/abc12345
            </p>
          </div>
        </div>
      </div>
    </WebShell>
  );
}
