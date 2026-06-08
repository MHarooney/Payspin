'use client';

import { AdminWebhookListItem, Paginated } from '@payspin/shared-types';
import { useQuery } from '@tanstack/react-query';
import { useState } from 'react';
import { OpsLoadingPanel } from '@/components/ops/emblem-loader';
import { OpsCard, OpsPill, OpsSectionHead } from '@/components/ops/primitives';
import { apiRequest } from '@/lib/admin-api';
import { relativeTime } from '@/lib/format';

export default function WebhooksPage() {
  const [page, setPage] = useState(1);
  const [selected, setSelected] = useState<string | null>(null);

  const { data, isLoading } = useQuery({
    queryKey: ['webhooks', page],
    queryFn: () => apiRequest<Paginated<AdminWebhookListItem>>('/webhooks', { query: { page } }),
  });

  const detail = useQuery({
    queryKey: ['webhook-detail', selected],
    queryFn: () => apiRequest<{ payloadSummary: Record<string, unknown>; linkedPaymentId: string | null; eventType: string; processedAt: string | null }>(`/webhooks/${selected}`),
    enabled: !!selected,
  });

  const items = data?.items ?? [];

  return (
    <div className="content">
      <OpsSectionHead title="Webhooks" sub={`${data?.total ?? 0} events · read-only preview`} />
      <div className="two-col" style={{ gap: 16 }}>
        <OpsCard title={undefined} count={undefined} style={{ minHeight: 300 }}>
          {isLoading ? <OpsLoadingPanel label="Loading webhooks…" size={32} /> : (
            <table>
              <thead><tr><th>Type</th><th>Event ID</th><th>Processed</th><th>Received</th></tr></thead>
              <tbody>
                {items.map((e) => (
                  <tr key={e.id} onClick={() => setSelected(e.id)} style={{ cursor: 'pointer', background: selected === e.id ? 'var(--accent-dim)' : undefined }}>
                    <td><span className="mono" style={{ fontSize: 11 }}>{e.eventType}</span></td>
                    <td className="mono" style={{ fontSize: 10, color: 'var(--muted)' }}>{e.eventId.slice(0, 16)}…</td>
                    <td>{e.processedAt ? <OpsPill tone="ok">done</OpsPill> : <OpsPill tone="pend">pending</OpsPill>}</td>
                    <td className="hint">{relativeTime(e.createdAt)}</td>
                  </tr>
                ))}
                {items.length === 0 && <tr><td colSpan={4}><div className="empty">No webhook events. Trigger a payment to generate one.</div></td></tr>}
              </tbody>
            </table>
          )}
          {data && data.totalPages > 1 && (
            <div className="table-browser-pagination">
              <button className="mini-btn" disabled={page <= 1} onClick={() => setPage((p) => p - 1)}>← Prev</button>
              <span className="hint">{page} / {data.totalPages}</span>
              <button className="mini-btn" disabled={page >= data.totalPages} onClick={() => setPage((p) => p + 1)}>Next →</button>
            </div>
          )}
        </OpsCard>

        <OpsCard title={selected ? 'Event detail' : 'Select an event'} count={undefined} style={{ minHeight: 300 }}>
          {selected && detail.data ? (
            <div>
              <div className="field-grid" style={{ marginBottom: 16 }}>
                <div className="field-row"><span className="field-label">Type</span><span className="mono">{detail.data.eventType}</span></div>
                <div className="field-row"><span className="field-label">Linked payment</span><span className="mono">{detail.data.linkedPaymentId ?? '—'}</span></div>
                <div className="field-row"><span className="field-label">Processed at</span><span className="hint">{detail.data.processedAt ? relativeTime(detail.data.processedAt) : 'Pending'}</span></div>
              </div>
              <div className="schema-section-label" style={{ marginBottom: 8 }}>Payload (redacted)</div>
              <pre style={{ fontSize: 10, background: 'var(--panel-2)', padding: 12, borderRadius: 8, overflow: 'auto', maxHeight: 300 }}>
                {JSON.stringify(detail.data.payloadSummary, null, 2)}
              </pre>
            </div>
          ) : selected && detail.isLoading ? (
            <OpsLoadingPanel label="Loading detail…" size={28} />
          ) : (
            <div className="empty">Select a webhook event to inspect its payload.</div>
          )}
        </OpsCard>
      </div>
    </div>
  );
}
