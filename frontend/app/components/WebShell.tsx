import PayspinHeader from './PayspinHeader';
import PayspinFooter from './PayspinFooter';

/**
 * Dark, brand-glow page wrapper shared by the landing, callback, success and
 * error pages so every payer screen feels like one product.
 */
export default function WebShell({
  children,
  showFooter = true,
}: {
  children: React.ReactNode;
  showFooter?: boolean;
}) {
  return (
    <main className="ps-page">
      <div className="ps-shell">
        <PayspinHeader />
        {children}
        {showFooter && <PayspinFooter />}
      </div>
    </main>
  );
}
