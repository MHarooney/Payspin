'use client';

import { initiatePayment } from '@/lib/api';
import { useState } from 'react';

export default function PayButton({
  code,
  amountCents,
  currency,
  openAmount = false,
}: {
  code: string;
  amountCents?: number;
  currency: string;
  openAmount?: boolean;
}) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [amountInput, setAmountInput] = useState('');

  function resolveAmountCents(): number | undefined {
    if (!openAmount) return amountCents;
    const value = Number.parseFloat(amountInput.replace(',', '.'));
    if (!Number.isFinite(value) || value <= 0) return undefined;
    return Math.round(value * 100);
  }

  async function handlePay() {
    const cents = resolveAmountCents();
    if (openAmount && cents == null) {
      setError('Please enter an amount greater than 0.');
      return;
    }
    setLoading(true);
    setError(null);
    try {
      const result = await initiatePayment(code, cents);
      window.location.href = result.redirectUrl;
    } catch (e) {
      setError(
        e instanceof Error
          ? e.message
          : 'Could not start the payment. Please try again.',
      );
      setLoading(false);
    }
  }

  return (
    <div>
      {openAmount && (
        <label style={styles.field}>
          <span style={styles.fieldLabel}>Amount ({currency})</span>
          <input
            type="number"
            inputMode="decimal"
            min="0.01"
            step="0.01"
            placeholder="0.00"
            value={amountInput}
            onChange={(e) => {
              setAmountInput(e.target.value);
              setError(null);
            }}
            disabled={loading}
            style={styles.input}
          />
        </label>
      )}
      <button
        onClick={handlePay}
        disabled={loading}
        style={{
          width: '100%',
          padding: '16px 24px',
          border: 'none',
          borderRadius: 28,
          background: 'linear-gradient(90deg,#FC00FF,#07D8DD)',
          color: '#fff',
          fontSize: 16,
          fontWeight: 600,
          cursor: loading ? 'wait' : 'pointer',
        }}
      >
        {loading ? 'Redirecting to your bank…' : 'Pay with my bank'}
      </button>
      {error && <p style={{ color: '#ef4444', fontSize: 14, marginTop: 12 }}>{error}</p>}
    </div>
  );
}

const styles: Record<string, React.CSSProperties> = {
  field: { display: 'block', marginBottom: 16 },
  fieldLabel: { display: 'block', fontSize: 13, color: '#6b7280', marginBottom: 6 },
  input: {
    width: '100%',
    padding: '14px 16px',
    border: '1px solid #d1d5db',
    borderRadius: 12,
    fontSize: 18,
    boxSizing: 'border-box',
  },
};
