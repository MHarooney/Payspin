'use client';

import { AuditEventDto, Paginated } from '@payspin/shared-types';
import { useQuery } from '@tanstack/react-query';
import { useState } from 'react';
import { Column, OpsDataTable } from '@/components/ops/data-table';
import { OpsCard, OpsPill, OpsSectionHead } from '@/components/ops/primitives';
import { apiRequest } from '@/lib/admin-api';
import { clock } from '@/lib/format';

const ACTION_TONE: Record<string, string> = {
  KYC_APPROVE: 'blue',
  USER_FREEZE: 'fail',
  TX_RETRY: 'ok',
  CONFIG_UPDATE: 'pend',
  FLAG_TOGGLE: 'blue',
  KILL_SWITCH_ON: 'fail',
  KILL_SWITCH_OFF: 'ok',
  ADMIN_LOGIN: 'blue',
  USER_STATE_UPDATE: 'pend',
};

function summarize(before: unknown, after: unknown): string {
  const b = before as Record<string, unknown> | null;
  const a = after as Record<string, unknown> | null;
  if (!a) return '—';
  const key = Object.keys(a)[0];
  if (!key) return '—';
  return `${b?.[key] ?? '∅'} → ${a[key]}`;
}

export default function AuditPage() {
  const [page, setPage] = useState(1);
  const { data } = useQuery({
    queryKey: ['audit', page],
    queryFn: () => apiRequest<Paginated<AuditEventDto>>('/audit', { query: { page, pageSize: 25 } }),
  });

  const columns: Column<AuditEventDto>[] = [
    { header: 'Time', cell: (e) => <span className="mono">{clock(e.createdAt)}</span> },
    { header: 'Admin', cell: (e) => e.adminEmail },
    { header: 'Action', cell: (e) => <OpsPill tone={ACTION_TONE[e.action] ?? 'blue'}>{e.action}</OpsPill> },
    { header: 'Target', cell: (e) => <span className="mono">{e.targetType ? `${e.targetType}:${e.targetId ?? ''}` : '—'}</span> },
    { header: 'Before → After', cell: (e) => <span className="hint">{summarize(e.before, e.after)}</span> },
    { header: 'IP', cell: (e) => <span className="mono">{e.ip ?? 'internal'}</span> },
  ];

  return (
    <>
      <OpsSectionHead title="Audit log" sub="Immutable · append-only · every admin action recorded" />
      <OpsCard>
        <OpsDataTable columns={columns} rows={data?.items ?? []} rowKey={(e) => e.id} empty="No audit events yet." />
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
