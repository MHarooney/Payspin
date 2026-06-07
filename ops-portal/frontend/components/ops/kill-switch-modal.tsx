'use client';

import { KillSwitchState } from '@payspin/shared-types';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { useState } from 'react';
import { apiRequest } from '@/lib/admin-api';

export function KillSwitchModal({
  state,
  onClose,
}: {
  state: KillSwitchState | undefined;
  onClose: () => void;
}) {
  const qc = useQueryClient();
  const turningOn = !state?.active;
  const [reason, setReason] = useState('');
  const [totpCode, setTotpCode] = useState('');

  const mutation = useMutation({
    mutationFn: () =>
      apiRequest<KillSwitchState>('/kill-switch', {
        method: 'POST',
        body: { active: turningOn, reason, totpCode: totpCode || undefined },
      }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['kill-switch'] });
      qc.invalidateQueries({ queryKey: ['audit'] });
      onClose();
    },
  });

  return (
    <div className="modal-bg" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <h2>{turningOn ? 'Activate kill switch' : 'Deactivate kill switch'}</h2>
        <p>
          {turningOn
            ? 'This immediately pauses all new transactions platform-wide. In-flight bank settlements continue. Use only for active incidents.'
            : 'This re-enables new transactions across the platform.'}
        </p>
        <textarea
          rows={3}
          placeholder="Reason (required, logged to audit trail)…"
          value={reason}
          onChange={(e) => setReason(e.target.value)}
        />
        <input
          placeholder="2FA / TOTP code (optional — verification stubbed)"
          value={totpCode}
          onChange={(e) => setTotpCode(e.target.value)}
        />
        <div className="modal-note">Attributed to your admin account · IP logged · audit entry created</div>
        {mutation.isError && (
          <div className="error-text">{(mutation.error as Error).message}</div>
        )}
        <div className="modal-actions">
          <button className="btn ghost" onClick={onClose}>
            Cancel
          </button>
          <button
            className={`btn ${turningOn ? 'danger' : 'primary'}`}
            disabled={reason.trim().length < 8 || mutation.isPending}
            onClick={() => mutation.mutate()}
          >
            {mutation.isPending
              ? 'Working…'
              : turningOn
                ? 'Confirm & pause platform'
                : 'Confirm & resume platform'}
          </button>
        </div>
      </div>
    </div>
  );
}
