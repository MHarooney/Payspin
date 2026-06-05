'use client';

import { initiatePayment } from '@/lib/api';
import { useState } from 'react';

const MAX_MESSAGE_LENGTH = 35;

export default function PayButton({
  code,
  amountCents,
  currency,
  payeeName,
  openAmount = false,
}: {
  code: string;
  amountCents?: number;
  currency: string;
  payeeName?: string;
  openAmount?: boolean;
}) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [amountInput, setAmountInput] = useState('');
  const [showMessage, setShowMessage] = useState(false);
  const [message, setMessage] = useState('');

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
      const trimmed = message.trim();
      const result = await initiatePayment(code, cents, trimmed || undefined);
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
        <label className="ps-field">
          <span className="ps-field__label">Amount ({currency})</span>
          <input
            className="ps-input"
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
          />
        </label>
      )}

      {!showMessage ? (
        <button
          type="button"
          className="ps-message-toggle"
          onClick={() => setShowMessage(true)}
          disabled={loading}
        >
          + Add message{payeeName ? ` for ${payeeName}` : ''}?
        </button>
      ) : (
        <div className="ps-message-wrap">
          <textarea
            className="ps-textarea"
            placeholder="E.g. thanks for lunch"
            maxLength={MAX_MESSAGE_LENGTH}
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            disabled={loading}
            aria-label="Message for the requester"
          />
          <div className="ps-charcount">
            {MAX_MESSAGE_LENGTH - message.length}
          </div>
        </div>
      )}

      <button
        type="button"
        className="ps-cta"
        onClick={handlePay}
        disabled={loading}
      >
        {loading ? 'Redirecting to your bank…' : 'Pay with my bank'}
      </button>

      <div className="ps-trust">
        <span className="ps-trust__dot" aria-hidden />
        Secured by open banking · Powered by Yapily
      </div>

      {error && <p className="ps-error-text">{error}</p>}
    </div>
  );
}
