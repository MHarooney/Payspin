'use client';

import { ReactNode, useEffect, useState } from 'react';

export function OpsModal({
  title,
  children,
  footer,
  onClose,
  maxWidth = 440,
  titleTone,
}: {
  title: ReactNode;
  children: ReactNode;
  footer?: ReactNode;
  onClose?: () => void;
  maxWidth?: number;
  titleTone?: 'danger';
}) {
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && onClose) onClose();
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [onClose]);

  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div
        className="modal"
        style={{ maxWidth }}
        onClick={(e) => e.stopPropagation()}
        role="dialog"
        aria-modal="true"
      >
        <h3 style={{ marginBottom: 12, color: titleTone === 'danger' ? 'var(--red)' : undefined }}>{title}</h3>
        {children}
        {footer && <div className="modal-actions">{footer}</div>}
      </div>
    </div>
  );
}

export function OpsConfirmModal({
  title,
  message,
  confirmLabel = 'Confirm',
  confirmTone = 'danger',
  matchText,
  onConfirm,
  onClose,
  isPending,
  error,
}: {
  title: string;
  message: ReactNode;
  confirmLabel?: string;
  confirmTone?: 'danger' | 'default';
  matchText?: string;
  onConfirm: () => void;
  onClose: () => void;
  isPending?: boolean;
  error?: string;
}) {
  const [typed, setTyped] = useState('');

  const disabled = isPending || (matchText ? typed !== matchText : false);

  return (
    <OpsModal
      title={title}
      titleTone={confirmTone === 'danger' ? 'danger' : undefined}
      onClose={onClose}
      footer={
        <>
          <button className="mini-btn" onClick={onClose} disabled={isPending}>
            Cancel
          </button>
          <button
            className={`mini-btn${confirmTone === 'danger' ? ' danger' : ''}`}
            disabled={disabled}
            onClick={onConfirm}
          >
            {isPending ? 'Working…' : confirmLabel}
          </button>
        </>
      }
    >
      <p style={{ color: 'var(--muted)', fontSize: 13, marginBottom: 16 }}>{message}</p>
      {matchText && (
        <input
          className="search"
          style={{ width: '100%', marginBottom: 16 }}
          value={typed}
          onChange={(e) => setTyped(e.target.value)}
          placeholder={matchText}
        />
      )}
      {error && <div style={{ color: 'var(--red)', fontSize: 12 }}>{error}</div>}
    </OpsModal>
  );
}
