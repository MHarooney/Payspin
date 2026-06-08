'use client';

import { AdminUserListItem, AdminUsersSummary, Paginated } from '@payspin/shared-types';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useRouter } from 'next/navigation';
import { useState } from 'react';
import { Column, OpsDataTable } from '@/components/ops/data-table';
import { OpsLoadingPanel } from '@/components/ops/emblem-loader';
import { OpsCard, OpsKpiStrip, OpsPill, OpsSectionHead } from '@/components/ops/primitives';
import { OpsRowMenu, OpsEmptyState } from '@/components/ops/ops-row-menu';
import { useOpsToast } from '@/components/ops/ops-toast';
import {
  CreateUserModal,
  DeleteUserModal,
  EditUserModal,
  FreezeUserModal,
  ResetPasswordModal,
} from '@/components/ops/users/user-modals';
import { apiRequest } from '@/lib/admin-api';
import { useAuth } from '@/lib/auth';
import { eur, relativeTime, statusPill } from '@/lib/format';

const PRESENCE_TONE: Record<string, string> = { online: 'ok', recent: 'pend', offline: 'blue', never: 'blue' };
const PRESENCE_LABEL: Record<string, string> = {
  online: '● Online',
  recent: '◐ Recent',
  offline: '○ Offline',
  never: '— Never',
};

type ModalKind = 'edit' | 'delete' | 'reset' | 'freeze' | null;

export default function UsersPage() {
  const router = useRouter();
  const qc = useQueryClient();
  const { admin } = useAuth();
  const { toast } = useOpsToast();
  const canAct = admin?.role === 'SUPER_ADMIN' || admin?.role === 'OPS';
  const isSuperAdmin = admin?.role === 'SUPER_ADMIN';
  const [status, setStatus] = useState('');
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [includeDeleted, setIncludeDeleted] = useState(false);
  const [showCreate, setShowCreate] = useState(false);
  const [modal, setModal] = useState<{ kind: ModalKind; user: AdminUserListItem | null }>({ kind: null, user: null });

  const { data, isLoading } = useQuery({
    queryKey: ['users', status, search, page, includeDeleted],
    queryFn: () =>
      apiRequest<Paginated<AdminUserListItem>>('/users', {
        query: { status: status || undefined, search: search || undefined, page, includeDeleted: includeDeleted ? '1' : undefined },
      }),
  });

  const { data: summary } = useQuery({
    queryKey: ['users-summary'],
    queryFn: () => apiRequest<AdminUsersSummary>('/users/summary'),
  });

  const setState = useMutation({
    mutationFn: (vars: { id: string; body: Record<string, unknown> }) =>
      apiRequest(`/users/${vars.id}/state`, { method: 'POST', body: vars.body }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['users'] });
      qc.invalidateQueries({ queryKey: ['users-summary'] });
      qc.invalidateQueries({ queryKey: ['audit'] });
      toast('User state updated');
    },
    onError: (e) => toast(String((e as Error).message), 'fail'),
  });

  const refresh = () => {
    qc.invalidateQueries({ queryKey: ['users'] });
    qc.invalidateQueries({ queryKey: ['users-summary'] });
  };

  const target = modal.user;

  const columns: Column<AdminUserListItem>[] = [
    {
      header: 'User',
      cell: (u) => (
        <div>
          <b style={{ color: u.isDeleted ? 'var(--muted)' : undefined }}>{u.displayName ?? 'Unnamed'}</b>
          <br />
          <span className="mono">{u.email}</span>
        </div>
      ),
    },
    { header: 'Presence', cell: (u) => <OpsPill tone={PRESENCE_TONE[u.presence]}>{PRESENCE_LABEL[u.presence]}</OpsPill> },
    { header: 'Last login', cell: (u) => <span className="hint">{u.lastLoginAt ? relativeTime(u.lastLoginAt) : '—'}</span> },
    {
      header: 'KYC',
      cell: (u) => (
        <OpsPill tone={statusPill(u.kycStatus)}>
          {u.kycTier ? `${u.kycTier} ` : ''}
          {u.kycStatus.toLowerCase()}
        </OpsPill>
      ),
    },
    { header: 'Status', cell: (u) => <OpsPill tone={statusPill(u.status)}>{u.status}</OpsPill> },
    { header: 'Volume', cell: (u) => eur(u.lifetimeVolumeCents) },
    { header: 'Devices', cell: (u) => <span className="hint">{u.registeredDeviceCount}</span> },
    {
      header: '',
      cell: (u) =>
        canAct && !u.isDeleted ? (
          <OpsRowMenu
            items={[
              { label: 'View profile', onClick: () => router.push(`/users/${u.id}`) },
              { label: 'Edit', onClick: () => setModal({ kind: 'edit', user: u }) },
              { label: 'Reset password', onClick: () => setModal({ kind: 'reset', user: u }) },
              ...(u.kycStatus !== 'VERIFIED'
                ? [{ label: 'Approve KYC', onClick: () => setState.mutate({ id: u.id, body: { kycStatus: 'VERIFIED' } }) }]
                : []),
              u.status === 'FROZEN'
                ? { label: 'Unfreeze', onClick: () => setState.mutate({ id: u.id, body: { status: 'ACTIVE' } }) }
                : { label: 'Freeze', onClick: () => setModal({ kind: 'freeze', user: u }), tone: 'danger' as const },
              ...(isSuperAdmin
                ? [{ label: 'Delete', onClick: () => setModal({ kind: 'delete', user: u }), tone: 'danger' as const }]
                : []),
            ]}
          />
        ) : (
          <span className="hint">{u.isDeleted ? 'deleted' : '—'}</span>
        ),
    },
  ];

  const kpis = summary
    ? [
        { label: 'Total users', value: String(summary.total), trend: null, direction: 'flat' as const },
        { label: 'Online', value: String(summary.online), trend: null, direction: 'flat' as const },
        { label: 'Pending KYC', value: String(summary.pendingKyc), trend: null, direction: 'flat' as const },
        { label: 'Frozen', value: String(summary.frozen), trend: null, direction: 'flat' as const },
      ]
    : [];

  return (
    <>
      {showCreate && (
        <CreateUserModal
          onSuccess={refresh}
          onClose={() => setShowCreate(false)}
          onCreated={() => toast('User created')}
        />
      )}
      {target && modal.kind === 'edit' && (
        <EditUserModal
          user={target}
          isSuperAdmin={isSuperAdmin}
          onSuccess={() => { refresh(); toast('Profile updated'); }}
          onClose={() => setModal({ kind: null, user: null })}
        />
      )}
      {target && modal.kind === 'reset' && (
        <ResetPasswordModal
          userId={target.id}
          onClose={() => setModal({ kind: null, user: null })}
          onSuccess={() => toast('Password reset')}
        />
      )}
      {target && modal.kind === 'delete' && (
        <DeleteUserModal
          user={target}
          onSuccess={() => { refresh(); toast('User deleted'); router.push('/users'); }}
          onClose={() => setModal({ kind: null, user: null })}
        />
      )}
      {target && modal.kind === 'freeze' && (
        <FreezeUserModal
          userLabel={target.displayName ?? target.email}
          onConfirm={(reason) => {
            setState.mutate({ id: target.id, body: { status: 'FROZEN', reason } });
            setModal({ kind: null, user: null });
          }}
          onClose={() => setModal({ kind: null, user: null })}
        />
      )}

      <OpsSectionHead title="Users & KYC queue" sub={`${data?.total ?? 0} users`}>
        {canAct && (
          <button className="mini-btn" onClick={() => setShowCreate(true)}>
            + New user
          </button>
        )}
      </OpsSectionHead>

      {kpis.length > 0 && <OpsKpiStrip kpis={kpis} columns={4} />}

      <div className="filters">
        <select value={status} onChange={(e) => { setStatus(e.target.value); setPage(1); }}>
          <option value="">All states</option>
          <option value="ACTIVE">Active</option>
          <option value="FROZEN">Frozen</option>
          <option value="SUSPENDED">Suspended</option>
          <option value="BLOCKED">Blocked</option>
        </select>
        <input
          placeholder="Search name / email / phone…"
          style={{ flex: 1 }}
          value={search}
          onChange={(e) => { setSearch(e.target.value); setPage(1); }}
        />
        {isSuperAdmin && (
          <label style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 12, color: 'var(--muted)', cursor: 'pointer' }}>
            <input type="checkbox" checked={includeDeleted} onChange={(e) => setIncludeDeleted(e.target.checked)} /> Show deleted
          </label>
        )}
      </div>

      <OpsCard>
        {isLoading ? (
          <OpsLoadingPanel label="Loading users" />
        ) : (data?.items ?? []).length === 0 ? (
          <OpsEmptyState
            title="No users found"
            hint={canAct ? 'Create a test user to start sandbox payments.' : undefined}
            action={canAct ? <button className="mini-btn" onClick={() => setShowCreate(true)}>Create first test user</button> : undefined}
          />
        ) : (
          <OpsDataTable
            columns={columns}
            rows={data?.items ?? []}
            rowKey={(u) => u.id}
            onRowClick={(u) => router.push(`/users/${u.id}`)}
          />
        )}
      </OpsCard>

      {data && data.totalPages > 1 && (
        <div className="row-actions" style={{ justifyContent: 'flex-end' }}>
          <button className="mini-btn" disabled={page <= 1} onClick={() => setPage((p) => p - 1)}>
            Prev
          </button>
          <span className="hint" style={{ alignSelf: 'center' }}>
            Page {data.page} / {data.totalPages}
          </span>
          <button className="mini-btn" disabled={page >= data.totalPages} onClick={() => setPage((p) => p + 1)}>
            Next
          </button>
        </div>
      )}
    </>
  );
}
