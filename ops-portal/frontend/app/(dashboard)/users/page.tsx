'use client';

import { AdminUserListItem, Paginated } from '@payspin/shared-types';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useState } from 'react';
import { Column, OpsDataTable } from '@/components/ops/data-table';
import { OpsLoadingPanel } from '@/components/ops/emblem-loader';
import { OpsCard, OpsPill, OpsSectionHead } from '@/components/ops/primitives';
import { apiRequest } from '@/lib/admin-api';
import { useAuth } from '@/lib/auth';
import { eur, statusPill } from '@/lib/format';

const RISK_TONE: Record<string, string> = { LOW: 'ok', MEDIUM: 'pend', HIGH: 'fail' };

export default function UsersPage() {
  const qc = useQueryClient();
  const { admin } = useAuth();
  const canAct = admin?.role === 'SUPER_ADMIN' || admin?.role === 'OPS';
  const [status, setStatus] = useState('');
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);

  const { data, isLoading } = useQuery({
    queryKey: ['users', status, search, page],
    queryFn: () =>
      apiRequest<Paginated<AdminUserListItem>>('/users', {
        query: { status: status || undefined, search: search || undefined, page },
      }),
  });

  const setState = useMutation({
    mutationFn: (vars: { id: string; body: Record<string, unknown> }) =>
      apiRequest(`/users/${vars.id}/state`, { method: 'POST', body: vars.body }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['users'] });
      qc.invalidateQueries({ queryKey: ['audit'] });
    },
  });

  const columns: Column<AdminUserListItem>[] = [
    {
      header: 'User',
      cell: (u) => (
        <div>
          <b>{u.displayName ?? 'Unnamed'}</b>
          <br />
          <span className="mono">{u.email}</span>
        </div>
      ),
    },
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
    { header: 'Lifetime Vol', cell: (u) => eur(u.lifetimeVolumeCents) },
    { header: 'Risk', cell: (u) => <OpsPill tone={RISK_TONE[u.riskLevel] ?? 'blue'}>{u.riskLevel}</OpsPill> },
    { header: 'Bank', cell: (u) => (u.bankVerified ? <OpsPill tone="ok">verified</OpsPill> : <span className="hint">—</span>) },
    {
      header: 'Actions',
      cell: (u) =>
        canAct ? (
          <div className="row-actions">
            {u.kycStatus !== 'VERIFIED' && (
              <button
                className="mini-btn"
                onClick={() => setState.mutate({ id: u.id, body: { kycStatus: 'VERIFIED' } })}
              >
                Approve
              </button>
            )}
            {u.status === 'FROZEN' ? (
              <button className="mini-btn" onClick={() => setState.mutate({ id: u.id, body: { status: 'ACTIVE' } })}>
                Unfreeze
              </button>
            ) : (
              <button
                className="mini-btn danger"
                onClick={() => {
                  const reason = window.prompt('Reason for freezing this user?') ?? '';
                  setState.mutate({ id: u.id, body: { status: 'FROZEN', reason } });
                }}
              >
                Freeze
              </button>
            )}
          </div>
        ) : (
          <span className="hint">read-only</span>
        ),
    },
  ];

  return (
    <>
      <OpsSectionHead title="Users & KYC queue" sub={`${data?.total ?? 0} users`} />
      <div className="filters">
        <select
          value={status}
          onChange={(e) => {
            setStatus(e.target.value);
            setPage(1);
          }}
        >
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
          onChange={(e) => {
            setSearch(e.target.value);
            setPage(1);
          }}
        />
      </div>

      <OpsCard>
        {isLoading ? (
          <OpsLoadingPanel label="Loading users" />
        ) : (
          <OpsDataTable columns={columns} rows={data?.items ?? []} rowKey={(u) => u.id} empty="No users found." />
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
