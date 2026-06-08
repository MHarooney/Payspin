'use client';

import {
  AdminPaymentDetail,
  AdminPaymentListItem,
  Paginated,
} from '@payspin/shared-types';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useSearchParams } from 'next/navigation';
import { useEffect, useState, type ReactNode } from 'react';
import { Column, OpsDataTable } from '@/components/ops/data-table';
import { OpsLoadingPanel } from '@/components/ops/emblem-loader';
import { OpsCard, OpsPill, OpsSectionHead } from '@/components/ops/primitives';
import { apiRequest } from '@/lib/admin-api';
import { useAuth } from '@/lib/auth';
import { eurExact, relativeTime, statusPill } from '@/lib/format';

const STATUSES = ['', 'COMPLETED', 'PENDING', 'PROCESSING', 'AWAITING_AUTHORIZATION', 'FAILED', 'CANCELLED'];

export default function TransactionsPage() {
  const qc = useQueryClient();
  const { admin } = useAuth();
  const searchParams = useSearchParams();
  const canAct = admin?.role === 'SUPER_ADMIN' || admin?.role === 'OPS';
  const [status, setStatus] = useState('');
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [detailId, setDetailId] = useState<string | null>(null);

  useEffect(() => {
    const q = searchParams.get('search');
    if (q) setSearch(q);
  }, [searchParams]);

  const { data, isLoading } = useQuery({
    queryKey: ['transactions', status, search, page],
    queryFn: () =>
      apiRequest<Paginated<AdminPaymentListItem>>('/transactions', {
        query: { status: status || undefined, search: search || undefined, page },
      }),
  });

  const retry = useMutation({
    mutationFn: (id: string) => apiRequest(`/transactions/${id}/retry`, { method: 'POST' }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['transactions'] });
      qc.invalidateQueries({ queryKey: ['audit'] });
    },
  });

  const refresh = useMutation({
    mutationFn: (id: string) => apiRequest(`/transactions/${id}/refresh`, { method: 'POST' }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['transactions'] });
      qc.invalidateQueries({ queryKey: ['audit'] });
    },
  });

  const columns: Column<AdminPaymentListItem>[] = [
    { header: 'Tx ID', cell: (t) => <span className="mono">{t.id.slice(0, 10)}</span> },
    { header: 'Payee', cell: (t) => t.payeeName },
    { header: 'Amount', cell: (t) => <b>{eurExact(t.amountCents)}</b> },
    {
      header: 'Status',
      cell: (t) => <OpsPill tone={statusPill(t.status)}>{t.status.replace(/_/g, ' ').toLowerCase()}</OpsPill>,
    },
    { header: 'Yapily Ref', cell: (t) => <span className="mono">{t.yapilyPaymentId ?? '—'}</span> },
    { header: 'Time', cell: (t) => relativeTime(t.initiatedAt) },
    {
      header: 'Actions',
      cell: (t) => (
        <div className="row-actions">
          <button className="mini-btn" onClick={() => setDetailId(t.id)}>
            View
          </button>
          {canAct && ['FAILED', 'AWAITING_AUTHORIZATION', 'PENDING'].includes(t.status) && (
            <button className="mini-btn" disabled={retry.isPending} onClick={() => retry.mutate(t.id)}>
              Retry
            </button>
          )}
          {canAct && t.yapilyPaymentId && (
            <button className="mini-btn" disabled={refresh.isPending} onClick={() => refresh.mutate(t.id)}>
              Refresh
            </button>
          )}
        </div>
      ),
    },
  ];

  return (
    <>
      <OpsSectionHead title="Transactions" sub={`${data?.total ?? 0} payments`} />
      <div className="filters">
        <select
          value={status}
          onChange={(e) => {
            setStatus(e.target.value);
            setPage(1);
          }}
        >
          {STATUSES.map((s) => (
            <option key={s} value={s}>
              {s ? s.replace(/_/g, ' ') : 'All statuses'}
            </option>
          ))}
        </select>
        <input
          placeholder="Search amount / Yapily ID / short code…"
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
          <OpsLoadingPanel label="Loading transactions" />
        ) : (
          <OpsDataTable
            columns={columns}
            rows={data?.items ?? []}
            rowKey={(t) => t.id}
            empty="No transactions match these filters."
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

      {detailId && <TransactionDetail id={detailId} onClose={() => setDetailId(null)} />}
    </>
  );
}

function TransactionDetail({ id, onClose }: { id: string; onClose: () => void }) {
  const { data } = useQuery({
    queryKey: ['transaction', id],
    queryFn: () => apiRequest<AdminPaymentDetail>(`/transactions/${id}`),
  });

  return (
    <div className="modal-bg" onClick={onClose}>
      <div className="modal" style={{ width: 520 }} onClick={(e) => e.stopPropagation()}>
        <h2>Payment detail</h2>
        {!data ? (
          <OpsLoadingPanel label="Loading payment detail" size={36} />
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8, fontSize: 13 }}>
            <Row k="Tx ID" v={<span className="mono">{data.id}</span>} />
            <Row k="Amount" v={<b>{eurExact(data.amountCents)}</b>} />
            <Row k="Status" v={<OpsPill tone={statusPill(data.status)}>{data.status}</OpsPill>} />
            <Row k="Payee" v={data.payeeName} />
            <Row k="Short code" v={<span className="mono">/{data.shortCode}</span>} />
            <Row k="Payer bank" v={data.payerBankName ?? '—'} />
            <Row k="Yapily payment" v={<span className="mono">{data.yapilyPaymentId ?? '—'}</span>} />
            <Row k="Yapily auth req" v={<span className="mono">{data.yapilyAuthRequestId ?? '—'}</span>} />
            <Row k="Idempotency" v={<span className="mono">{data.idempotencyKey ?? '—'}</span>} />
            <Row k="Initiated" v={new Date(data.initiatedAt).toLocaleString()} />
            <Row k="Completed" v={data.completedAt ? new Date(data.completedAt).toLocaleString() : '—'} />
          </div>
        )}
        <div className="modal-actions" style={{ marginTop: 18 }}>
          <button className="btn ghost" onClick={onClose}>
            Close
          </button>
        </div>
      </div>
    </div>
  );
}

function Row({ k, v }: { k: string; v: ReactNode }) {
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', gap: 16, borderBottom: '1px solid var(--border)', paddingBottom: 6 }}>
      <span className="hint">{k}</span>
      <span style={{ textAlign: 'right' }}>{v}</span>
    </div>
  );
}
