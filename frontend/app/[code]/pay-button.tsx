'use client';

import { initiatePayment } from '@/lib/api';
import { useState } from 'react';

export default function PayButton({
  code,
  amountCents,
}: {
  code: string;
  amountCents?: number;
}) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handlePay() {
    setLoading(true);
    setError(null);
    try {
      const result = await initiatePayment(code, amountCents);
      window.location.href = result.redirectUrl;
    } catch {
      setError('Could not start payment. Please try again.');
      setLoading(false);
    }
  }

  return (
    <div>
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
