'use client';

import { AdminRole, AdminStaffListItem } from '@payspin/shared-types';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useState } from 'react';
import { OpsLoadingPanel } from '@/components/ops/emblem-loader';
import { OpsCard, OpsPill, OpsSectionHead } from '@/components/ops/primitives';
import { apiRequest } from '@/lib/admin-api';
import { useAuth } from '@/lib/auth';
import { relativeTime } from '@/lib/format';

const ROLE_TONE: Record<string, string> = { SUPER_ADMIN: 'fail', OPS: 'pend', SUPPORT: 'blue', READ_ONLY: 'blue' };

function CreateAdminModal({ onSuccess, onClose }: { onSuccess: () => void; onClose: () => void }) {
  const [form, setForm] = useState({ email: '', displayName: '', role: 'OPS' as AdminRole, tempPassword: '' });
  const create = useMutation({
    mutationFn: () => apiRequest('/admin-users', { method: 'POST', body: { ...form } }),
    onSuccess: () => { onSuccess(); onClose(); },
  });
  return (
    <div className="modal-backdrop"><div className="modal" style={{ maxWidth: 420 }}>
      <h3 style={{ marginBottom: 16 }}>Create admin user</h3>
      {[
        { label: 'Email *', key: 'email', type: 'email', ph: 'admin@payspin.app' },
        { label: 'Display name', key: 'displayName', type: 'text', ph: 'Jane Ops' },
        { label: 'Temp password *', key: 'tempPassword', type: 'password', ph: 'Min 8 chars' },
      ].map(({ label, key, type, ph }) => (
        <div key={key} style={{ marginBottom: 12 }}>
          <label style={{ fontSize: 12, color: 'var(--muted)', display: 'block', marginBottom: 4 }}>{label}</label>
          <input className="search" type={type} style={{ width: '100%' }} value={(form as Record<string, string>)[key]} onChange={(e) => setForm((p) => ({ ...p, [key]: e.target.value }))} placeholder={ph} />
        </div>
      ))}
      <div style={{ marginBottom: 16 }}>
        <label style={{ fontSize: 12, color: 'var(--muted)', display: 'block', marginBottom: 4 }}>Role</label>
        <select className="search" style={{ width: '100%' }} value={form.role} onChange={(e) => setForm((p) => ({ ...p, role: e.target.value as AdminRole }))}>
          {(['OPS', 'SUPPORT', 'READ_ONLY', 'SUPER_ADMIN'] as AdminRole[]).map((r) => <option key={r} value={r}>{r}</option>)}
        </select>
      </div>
      {create.error && <div style={{ color: 'var(--red)', fontSize: 12, marginBottom: 12 }}>{String((create.error as Error).message)}</div>}
      <div style={{ display: 'flex', gap: 10, justifyContent: 'flex-end' }}>
        <button className="mini-btn" onClick={onClose}>Cancel</button>
        <button className="mini-btn" disabled={!form.email || !form.tempPassword || create.isPending} onClick={() => create.mutate()}>{create.isPending ? 'Creating…' : 'Create'}</button>
      </div>
    </div></div>
  );
}

export default function AdminUsersPage() {
  const qc = useQueryClient();
  const { admin } = useAuth();
  const [showCreate, setShowCreate] = useState(false);
  const isSuperAdmin = admin?.role === 'SUPER_ADMIN';

  const { data, isLoading } = useQuery({
    queryKey: ['admin-users'],
    queryFn: () => apiRequest<AdminStaffListItem[]>('/admin-users'),
    enabled: isSuperAdmin,
  });

  const deactivate = useMutation({
    mutationFn: (id: string) => apiRequest(`/admin-users/${id}`, { method: 'DELETE' }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin-users'] }),
  });

  if (!isSuperAdmin) {
    return <div className="content"><div className="empty">This page requires SUPER_ADMIN role.</div></div>;
  }

  return (
    <div className="content">
      {showCreate && <CreateAdminModal onSuccess={() => qc.invalidateQueries({ queryKey: ['admin-users'] })} onClose={() => setShowCreate(false)} />}

      <OpsSectionHead title="Admin users" sub="Ops staff management — SUPER_ADMIN only">
        <button className="mini-btn" onClick={() => setShowCreate(true)}>+ New admin</button>
      </OpsSectionHead>

      <OpsCard title={undefined} count={undefined}>
        {isLoading ? <OpsLoadingPanel label="Loading admins…" size={32} /> : (
          <table>
            <thead><tr><th>Email</th><th>Display name</th><th>Role</th><th>Status</th><th>Last login</th><th>Actions</th></tr></thead>
            <tbody>
              {(data ?? []).map((a) => (
                <tr key={a.id}>
                  <td className="mono">{a.email}</td>
                  <td>{a.displayName ?? '—'}</td>
                  <td><OpsPill tone={ROLE_TONE[a.role] ?? 'blue'}>{a.role}</OpsPill></td>
                  <td>{a.isActive ? <OpsPill tone="ok">Active</OpsPill> : <OpsPill tone="fail">Inactive</OpsPill>}</td>
                  <td className="hint">{a.lastLoginAt ? relativeTime(a.lastLoginAt) : '—'}</td>
                  <td>
                    {a.id !== admin?.id && a.isActive && (
                      <button className="mini-btn danger" disabled={deactivate.isPending} onClick={() => deactivate.mutate(a.id)}>Deactivate</button>
                    )}
                  </td>
                </tr>
              ))}
              {!data?.length && <tr><td colSpan={6}><div className="empty">No admin users found.</div></td></tr>}
            </tbody>
          </table>
        )}
      </OpsCard>
    </div>
  );
}
