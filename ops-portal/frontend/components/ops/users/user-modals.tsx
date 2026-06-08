'use client';

import { AdminUserDetail, AdminUserListItem, CreateUserAdminResult } from '@payspin/shared-types';
import { useMutation } from '@tanstack/react-query';
import Link from 'next/link';
import { useState } from 'react';
import { OpsConfirmModal, OpsModal } from '@/components/ops/ops-modal';
import { CopyButton } from '@/components/ops/copy-button';
import { OpsCard } from '@/components/ops/primitives';
import { apiRequest } from '@/lib/admin-api';

type UserLike = Pick<AdminUserListItem, 'id' | 'email' | 'displayName' | 'phoneE164'>;

export function CreateUserModal({
  onSuccess,
  onClose,
  onCreated,
}: {
  onSuccess: () => void;
  onClose: () => void;
  onCreated?: (result: CreateUserAdminResult) => void;
}) {
  const [form, setForm] = useState({ email: '', displayName: '', phone: '', tempPassword: '' });
  const [result, setResult] = useState<CreateUserAdminResult | null>(null);
  const f = (k: keyof typeof form) => (e: React.ChangeEvent<HTMLInputElement>) =>
    setForm((p) => ({ ...p, [k]: e.target.value }));

  const create = useMutation({
    mutationFn: () =>
      apiRequest<CreateUserAdminResult>('/users', {
        method: 'POST',
        body: {
          email: form.email,
          displayName: form.displayName || undefined,
          phoneE164: form.phone || undefined,
          tempPassword: form.tempPassword || undefined,
        },
      }),
    onSuccess: (data) => {
      setResult(data);
      onCreated?.(data);
    },
  });

  if (result) {
    return (
      <OpsModal title="User created" onClose={() => { onSuccess(); onClose(); }}>
        <div className="field-grid" style={{ marginBottom: 16 }}>
          <div className="field-row">
            <span className="field-label">Email</span>
            <span className="mono">{result.email}</span>
          </div>
          <div className="field-row">
            <span className="field-label">Temp password</span>
            <span className="mono" style={{ color: 'var(--accent-2)' }}>
              {result.tempPassword}
            </span>
            <CopyButton value={result.tempPassword} />
          </div>
        </div>
        <p style={{ color: 'var(--muted)', fontSize: 12, marginBottom: 16 }}>Share this password securely.</p>
        <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
          <Link href={`/users/${result.id}`} className="mini-btn" onClick={() => { onSuccess(); onClose(); }}>
            Open profile
          </Link>
          <Link href={`/users/${result.id}?tab=test`} className="mini-btn" onClick={() => { onSuccess(); onClose(); }}>
            Run test setup
          </Link>
          <button className="mini-btn" onClick={() => { onSuccess(); onClose(); }}>
            Close
          </button>
        </div>
      </OpsModal>
    );
  }

  return (
    <OpsModal
      title="Create consumer user"
      onClose={onClose}
      footer={
        <>
          <button className="mini-btn" onClick={onClose}>
            Cancel
          </button>
          <button className="mini-btn" disabled={!form.email || create.isPending} onClick={() => create.mutate()}>
            {create.isPending ? 'Creating…' : 'Create user'}
          </button>
        </>
      }
    >
      {[
        { label: 'Email *', key: 'email' as const, type: 'email', ph: 'user@example.com' },
        { label: 'Display name', key: 'displayName' as const, type: 'text', ph: 'Jane Doe' },
        { label: 'Phone (E.164)', key: 'phone' as const, type: 'tel', ph: '+31612345678' },
        { label: 'Temp password', key: 'tempPassword' as const, type: 'password', ph: 'Leave blank to auto-generate' },
      ].map(({ label, key, type, ph }) => (
        <div key={key} style={{ marginBottom: 12 }}>
          <label style={{ fontSize: 12, color: 'var(--muted)', display: 'block', marginBottom: 4 }}>{label}</label>
          <input className="search" type={type} style={{ width: '100%' }} value={form[key]} onChange={f(key)} placeholder={ph} />
        </div>
      ))}
      {create.error && (
        <div style={{ color: 'var(--red)', fontSize: 12 }}>{String((create.error as Error).message)}</div>
      )}
    </OpsModal>
  );
}

export function EditUserModal({
  user,
  isSuperAdmin,
  onSuccess,
  onClose,
}: {
  user: UserLike;
  isSuperAdmin?: boolean;
  onSuccess: () => void;
  onClose: () => void;
}) {
  const [displayName, setDisplayName] = useState(user.displayName ?? '');
  const [phone, setPhone] = useState(user.phoneE164 ?? '');
  const [email, setEmail] = useState(user.email);
  const patch = useMutation({
    mutationFn: () =>
      apiRequest(`/users/${user.id}`, {
        method: 'PATCH',
        body: {
          displayName: displayName || undefined,
          phoneE164: phone || undefined,
          ...(isSuperAdmin ? { email: email || undefined } : {}),
        },
      }),
    onSuccess: () => {
      onSuccess();
      onClose();
    },
  });

  return (
    <OpsModal
      title="Edit profile"
      onClose={onClose}
      footer={
        <>
          <button className="mini-btn" onClick={onClose}>
            Cancel
          </button>
          <button className="mini-btn" disabled={patch.isPending} onClick={() => patch.mutate()}>
            {patch.isPending ? 'Saving…' : 'Save'}
          </button>
        </>
      }
    >
      {isSuperAdmin && (
        <div style={{ marginBottom: 12 }}>
          <label style={{ fontSize: 12, color: 'var(--muted)', display: 'block', marginBottom: 4 }}>Email</label>
          <input className="search" type="email" style={{ width: '100%' }} value={email} onChange={(e) => setEmail(e.target.value)} />
        </div>
      )}
      <div style={{ marginBottom: 12 }}>
        <label style={{ fontSize: 12, color: 'var(--muted)', display: 'block', marginBottom: 4 }}>Display name</label>
        <input className="search" style={{ width: '100%' }} value={displayName} onChange={(e) => setDisplayName(e.target.value)} />
      </div>
      <div style={{ marginBottom: 12 }}>
        <label style={{ fontSize: 12, color: 'var(--muted)', display: 'block', marginBottom: 4 }}>Phone (E.164)</label>
        <input
          className="search"
          style={{ width: '100%' }}
          value={phone}
          onChange={(e) => setPhone(e.target.value)}
          placeholder="+31612345678"
        />
      </div>
      {patch.error && <div style={{ color: 'var(--red)', fontSize: 12 }}>{String((patch.error as Error).message)}</div>}
    </OpsModal>
  );
}

export function ResetPasswordModal({ userId, onClose, onSuccess }: { userId: string; onClose: () => void; onSuccess?: () => void }) {
  const [tempPassword, setTempPassword] = useState('');
  const [done, setDone] = useState<string | null>(null);
  const reset = useMutation({
    mutationFn: () =>
      apiRequest<{ tempPassword: string }>(`/users/${userId}/reset-password`, {
        method: 'POST',
        body: { tempPassword: tempPassword || undefined },
      }),
    onSuccess: (d) => {
      setDone(d.tempPassword);
      onSuccess?.();
    },
  });

  if (done) {
    return (
      <OpsModal title="Password reset" onClose={onClose}>
        <div className="field-row" style={{ marginBottom: 16 }}>
          <span className="field-label">New temp password</span>
          <span className="mono" style={{ color: 'var(--accent-2)' }}>
            {done}
          </span>
          <CopyButton value={done} />
        </div>
        <button className="mini-btn" onClick={onClose}>
          Close
        </button>
      </OpsModal>
    );
  }

  return (
    <OpsModal
      title="Reset password"
      onClose={onClose}
      footer={
        <>
          <button className="mini-btn" onClick={onClose}>
            Cancel
          </button>
          <button className="mini-btn" disabled={reset.isPending} onClick={() => reset.mutate()}>
            {reset.isPending ? 'Resetting…' : 'Reset'}
          </button>
        </>
      }
    >
      <input
        className="search"
        type="password"
        style={{ width: '100%' }}
        value={tempPassword}
        onChange={(e) => setTempPassword(e.target.value)}
        placeholder="Leave blank to auto-generate"
      />
    </OpsModal>
  );
}

export function DeleteUserModal({
  user,
  onSuccess,
  onClose,
}: {
  user: Pick<AdminUserDetail, 'id' | 'email'>;
  onSuccess: () => void;
  onClose: () => void;
}) {
  const del = useMutation({
    mutationFn: () => apiRequest(`/users/${user.id}`, { method: 'DELETE' }),
    onSuccess: () => {
      onSuccess();
      onClose();
    },
  });

  return (
    <OpsConfirmModal
      title="Soft-delete user"
      message={
        <>
          This will mark the account as deleted. The user cannot log in. Data is retained. Type <strong>{user.email}</strong>{' '}
          to confirm.
        </>
      }
      matchText={user.email}
      confirmLabel="Delete"
      onConfirm={() => del.mutate()}
      onClose={onClose}
      isPending={del.isPending}
      error={del.error ? String((del.error as Error).message) : undefined}
    />
  );
}

export function FreezeUserModal({
  userLabel,
  onConfirm,
  onClose,
}: {
  userLabel: string;
  onConfirm: (reason: string) => void;
  onClose: () => void;
}) {
  const [reason, setReason] = useState('');
  return (
    <OpsModal
      title="Freeze account"
      onClose={onClose}
      footer={
        <>
          <button className="mini-btn" onClick={onClose}>
            Cancel
          </button>
          <button
            className="mini-btn danger"
            disabled={reason.trim().length < 3}
            onClick={() => reason.trim().length >= 3 && onConfirm(reason.trim())}
          >
            Freeze
          </button>
        </>
      }
    >
      <p style={{ color: 'var(--muted)', fontSize: 13, marginBottom: 16 }}>
        Freeze <strong>{userLabel}</strong>.
      </p>
      <textarea
        className="search"
        style={{ width: '100%', minHeight: 80, resize: 'vertical' }}
        value={reason}
        onChange={(e) => setReason(e.target.value)}
        placeholder="Reason for freezing…"
      />
    </OpsModal>
  );
}

export function AdminNoteEditor({
  userId,
  initialNote,
  onSaved,
}: {
  userId: string;
  initialNote: string | null;
  onSaved: () => void;
}) {
  const [note, setNote] = useState(initialNote ?? '');
  const save = useMutation({
    mutationFn: () => apiRequest(`/users/${userId}/state`, { method: 'POST', body: { note } }),
    onSuccess: () => onSaved(),
  });

  return (
    <OpsCard title="Admin notes" count={undefined} style={{ marginBottom: 16 }}>
      <textarea
        className="search"
        style={{ width: '100%', minHeight: 88, resize: 'vertical', marginBottom: 12 }}
        value={note}
        onChange={(e) => setNote(e.target.value)}
        placeholder="Internal notes visible to ops staff only…"
      />
      <button className="mini-btn" disabled={save.isPending} onClick={() => save.mutate()}>
        {save.isPending ? 'Saving…' : 'Save note'}
      </button>
    </OpsCard>
  );
}
