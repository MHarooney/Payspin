'use client';

import { AdminUserListItem, AdminUserPresence, CreateUserAdminResult, Paginated } from '@payspin/shared-types';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useRouter } from 'next/navigation';
import { useState } from 'react';
import { Column, OpsDataTable } from '@/components/ops/data-table';
import { OpsLoadingPanel } from '@/components/ops/emblem-loader';
import { OpsCard, OpsPill, OpsSectionHead } from '@/components/ops/primitives';
import { apiRequest } from '@/lib/admin-api';
import { useAuth } from '@/lib/auth';
import { eur, relativeTime, statusPill } from '@/lib/format';

const RISK_TONE: Record<string, string> = { LOW: 'ok', MEDIUM: 'pend', HIGH: 'fail' };
const PRESENCE_TONE: Record<AdminUserPresence, string> = { online: 'ok', recent: 'pend', offline: 'blue', never: 'blue' };
const PRESENCE_LABEL: Record<AdminUserPresence, string> = { online: '● Online', recent: '◐ Recent', offline: '○ Offline', never: '— Never' };

function FreezeModal({ user, onConfirm, onClose }: { user: AdminUserListItem; onConfirm: (r: string) => void; onClose: () => void }) {
  const [reason, setReason] = useState('');
  return (
    <div className="modal-backdrop">
      <div className="modal" style={{ maxWidth: 440 }}>
        <h3 style={{ marginBottom: 12 }}>Freeze account</h3>
        <p style={{ color: 'var(--muted)', marginBottom: 16, fontSize: 13 }}>Freeze <strong>{user.displayName ?? user.email}</strong>.</p>
        <textarea className="search" style={{ width: '100%', minHeight: 80, resize: 'vertical', marginBottom: 16 }} value={reason} onChange={(e) => setReason(e.target.value)} placeholder="Reason for freezing…" />
        <div style={{ display: 'flex', gap: 10, justifyContent: 'flex-end' }}>
          <button className="mini-btn" onClick={onClose}>Cancel</button>
          <button className="mini-btn danger" disabled={reason.trim().length < 3} onClick={() => reason.trim().length >= 3 && onConfirm(reason.trim())}>Freeze</button>
        </div>
      </div>
    </div>
  );
}

function CreateUserModal({ onSuccess, onClose }: { onSuccess: () => void; onClose: () => void }) {
  const [form, setForm] = useState({ email: '', displayName: '', phone: '', tempPassword: '' });
  const [result, setResult] = useState<CreateUserAdminResult | null>(null);
  const f = (k: keyof typeof form) => (e: React.ChangeEvent<HTMLInputElement>) => setForm((p) => ({ ...p, [k]: e.target.value }));

  const create = useMutation({
    mutationFn: () => apiRequest<CreateUserAdminResult>('/users', {
      method: 'POST',
      body: { email: form.email, displayName: form.displayName || undefined, phoneE164: form.phone || undefined, tempPassword: form.tempPassword || undefined },
    }),
    onSuccess: (data) => setResult(data),
  });

  if (result) return (
    <div className="modal-backdrop"><div className="modal" style={{ maxWidth: 440 }}>
      <h3 style={{ marginBottom: 12 }}>User created</h3>
      <div className="field-grid" style={{ marginBottom: 16 }}>
        <div className="field-row"><span className="field-label">Email</span><span className="mono">{result.email}</span></div>
        <div className="field-row"><span className="field-label">Temp password</span><span className="mono" style={{ color: 'var(--accent-2)' }}>{result.tempPassword}</span></div>
      </div>
      <p style={{ color: 'var(--muted)', fontSize: 12, marginBottom: 16 }}>Share this password securely.</p>
      <button className="mini-btn" onClick={() => { onSuccess(); onClose(); }}>Close</button>
    </div></div>
  );

  return (
    <div className="modal-backdrop"><div className="modal" style={{ maxWidth: 440 }}>
      <h3 style={{ marginBottom: 16 }}>Create consumer user</h3>
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
      {create.error && <div style={{ color: 'var(--red)', fontSize: 12, marginBottom: 12 }}>{String((create.error as Error).message)}</div>}
      <div style={{ display: 'flex', gap: 10, justifyContent: 'flex-end' }}>
        <button className="mini-btn" onClick={onClose}>Cancel</button>
        <button className="mini-btn" disabled={!form.email || create.isPending} onClick={() => create.mutate()}>{create.isPending ? 'Creating…' : 'Create user'}</button>
      </div>
    </div></div>
  );
}

export default function UsersPage() {
  const router = useRouter();
  const qc = useQueryClient();
  const { admin } = useAuth();
  const canAct = admin?.role === 'SUPER_ADMIN' || admin?.role === 'OPS';
  const isSuperAdmin = admin?.role === 'SUPER_ADMIN';
  const [status, setStatus] = useState('');
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [includeDeleted, setIncludeDeleted] = useState(false);
  const [freezeTarget, setFreezeTarget] = useState<AdminUserListItem | null>(null);
  const [showCreate, setShowCreate] = useState(false);

  const { data, isLoading } = useQuery({
    queryKey: ['users', status, search, page, includeDeleted],
    queryFn: () => apiRequest<Paginated<AdminUserListItem>>('/users', {
      query: { status: status || undefined, search: search || undefined, page, includeDeleted: includeDeleted ? '1' : undefined },
    }),
  });

  const setState = useMutation({
    mutationFn: (vars: { id: string; body: Record<string, unknown> }) =>
      apiRequest(`/users/${vars.id}/state`, { method: 'POST', body: vars.body }),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['users'] }); qc.invalidateQueries({ queryKey: ['audit'] }); },
  });

  const columns: Column<AdminUserListItem>[] = [
    { header: 'User', cell: (u) => (<div><b style={{ color: u.isDeleted ? 'var(--muted)' : undefined }}>{u.displayName ?? 'Unnamed'}</b><br /><span className="mono">{u.email}</span></div>) },
    { header: 'Presence', cell: (u) => <OpsPill tone={PRESENCE_TONE[u.presence]}>{PRESENCE_LABEL[u.presence]}</OpsPill> },
    { header: 'Last login', cell: (u) => <span className="hint">{u.lastLoginAt ? relativeTime(u.lastLoginAt) : '—'}</span> },
    { header: 'KYC', cell: (u) => <OpsPill tone={statusPill(u.kycStatus)}>{u.kycTier ? `${u.kycTier} ` : ''}{u.kycStatus.toLowerCase()}</OpsPill> },
    { header: 'Status', cell: (u) => <OpsPill tone={statusPill(u.status)}>{u.status}</OpsPill> },
    { header: 'Volume', cell: (u) => eur(u.lifetimeVolumeCents) },
    { header: 'Devices', cell: (u) => <span className="hint">{u.registeredDeviceCount}</span> },
    {
      header: 'Actions', cell: (u) => canAct && !u.isDeleted ? (
        <div className="row-actions" onClick={(e) => e.stopPropagation()}>
          {u.kycStatus !== 'VERIFIED' && <button className="mini-btn" onClick={() => setState.mutate({ id: u.id, body: { kycStatus: 'VERIFIED' } })}>Approve</button>}
          {u.status === 'FROZEN'
            ? <button className="mini-btn" onClick={() => setState.mutate({ id: u.id, body: { status: 'ACTIVE' } })}>Unfreeze</button>
            : <button className="mini-btn danger" onClick={() => setFreezeTarget(u)}>Freeze</button>
          }
        </div>
      ) : <span className="hint">{u.isDeleted ? 'deleted' : 'read-only'}</span>,
    },
  ];

  return (
    <>
      {freezeTarget && (
        <FreezeModal user={freezeTarget} onConfirm={(reason) => { setState.mutate({ id: freezeTarget.id, body: { status: 'FROZEN', reason } }); setFreezeTarget(null); }} onClose={() => setFreezeTarget(null)} />
      )}
      {showCreate && <CreateUserModal onSuccess={() => qc.invalidateQueries({ queryKey: ['users'] })} onClose={() => setShowCreate(false)} />}

      <OpsSectionHead title="Users & KYC queue" sub={`${data?.total ?? 0} users`}>
        {canAct && <button className="mini-btn" onClick={() => setShowCreate(true)}>+ New user</button>}
      </OpsSectionHead>
      <div className="filters">
        <select value={status} onChange={(e) => { setStatus(e.target.value); setPage(1); }}>
          <option value="">All states</option>
          <option value="ACTIVE">Active</option>
          <option value="FROZEN">Frozen</option>
          <option value="SUSPENDED">Suspended</option>
          <option value="BLOCKED">Blocked</option>
        </select>
        <input placeholder="Search name / email / phone…" style={{ flex: 1 }} value={search} onChange={(e) => { setSearch(e.target.value); setPage(1); }} />
        {isSuperAdmin && (
          <label style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 12, color: 'var(--muted)', cursor: 'pointer' }}>
            <input type="checkbox" checked={includeDeleted} onChange={(e) => setIncludeDeleted(e.target.checked)} /> Show deleted
          </label>
        )}
      </div>
      <OpsCard>
        {isLoading ? <OpsLoadingPanel label="Loading users" /> : (
          <OpsDataTable columns={columns} rows={data?.items ?? []} rowKey={(u) => u.id} empty="No users found." onRowClick={(u) => router.push(`/users/${u.id}`)} />
        )}
      </OpsCard>
      {data && data.totalPages > 1 && (
        <div className="row-actions" style={{ justifyContent: 'flex-end' }}>
          <button className="mini-btn" disabled={page <= 1} onClick={() => setPage((p) => p - 1)}>Prev</button>
          <span className="hint" style={{ alignSelf: 'center' }}>Page {data.page} / {data.totalPages}</span>
          <button className="mini-btn" disabled={page >= data.totalPages} onClick={() => setPage((p) => p + 1)}>Next</button>
        </div>
      )}
    </>
  );
}
