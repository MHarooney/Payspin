'use client';

import { AdminPaymentLinkListItem, Paginated } from '@payspin/shared-types';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useRouter } from 'next/navigation';
import { useState } from 'react';
import { OpsLoadingPanel } from '@/components/ops/emblem-loader';
import { OpsCard, OpsPill, OpsSectionHead } from '@/components/ops/primitives';
import { apiRequest } from '@/lib/admin-api';
import { useAuth } from '@/lib/auth';
import { eur, relativeTime, statusPill } from '@/lib/format';

function CancelModal({ link, onSuccess, onClose }: { link: AdminPaymentLinkListItem; onSuccess: () => void; onClose: () => void }) {
  const cancel = useMutation({
    mutationFn: () => apiRequest(`/payment-links/${link.id}`, { method: 'PATCH', body: { action: 'cancel' } }),
    onSuccess: () => { onSuccess(); onClose(); },
  });
  return (
    <div className="modal-backdrop"><div className="modal" style={{ maxWidth: 400 }}>
      <h3 style={{ marginBottom: 12 }}>Cancel link</h3>
      <p style={{ color: 'var(--muted)', fontSize: 13, marginBottom: 16 }}>Cancel <strong>/{link.shortCode}</strong>? This cannot be undone.</p>
      {cancel.error && <div style={{ color: 'var(--red)', fontSize: 12, marginBottom: 12 }}>{String((cancel.error as Error).message)}</div>}
      <div style={{ display: 'flex', gap: 10, justifyContent: 'flex-end' }}>
        <button className="mini-btn" onClick={onClose}>Cancel</button>
        <button className="mini-btn danger" disabled={cancel.isPending} onClick={() => cancel.mutate()}>{cancel.isPending ? 'Cancelling…' : 'Confirm cancel'}</button>
      </div>
    </div></div>
  );
}

function ExtendModal({ link, onSuccess, onClose }: { link: AdminPaymentLinkListItem; onSuccess: () => void; onClose: () => void }) {
  const [days, setDays] = useState(7);
  const extend = useMutation({
    mutationFn: () => {
      const future = new Date(Date.now() + days * 86400000).toISOString();
      return apiRequest(`/payment-links/${link.id}`, { method: 'PATCH', body: { action: 'extend', expiresAt: future } });
    },
    onSuccess: () => { onSuccess(); onClose(); },
  });
  return (
    <div className="modal-backdrop"><div className="modal" style={{ maxWidth: 360 }}>
      <h3 style={{ marginBottom: 12 }}>Extend expiry</h3>
      <label style={{ fontSize: 12, color: 'var(--muted)', display: 'block', marginBottom: 8 }}>Extend by (days)</label>
      <input className="search" type="number" min={1} max={365} style={{ width: '100%', marginBottom: 16 }} value={days} onChange={(e) => setDays(Number(e.target.value))} />
      {extend.error && <div style={{ color: 'var(--red)', fontSize: 12, marginBottom: 12 }}>{String((extend.error as Error).message)}</div>}
      <div style={{ display: 'flex', gap: 10, justifyContent: 'flex-end' }}>
        <button className="mini-btn" onClick={onClose}>Cancel</button>
        <button className="mini-btn" disabled={extend.isPending} onClick={() => extend.mutate()}>{extend.isPending ? 'Extending…' : 'Extend'}</button>
      </div>
    </div></div>
  );
}

export default function PaymentLinksPage() {
  const router = useRouter();
  const qc = useQueryClient();
  const { admin } = useAuth();
  const canAct = admin?.role === 'SUPER_ADMIN' || admin?.role === 'OPS';
  const [page, setPage] = useState(1);
  const [cancelTarget, setCancelTarget] = useState<AdminPaymentLinkListItem | null>(null);
  const [extendTarget, setExtendTarget] = useState<AdminPaymentLinkListItem | null>(null);

  const { data, isLoading } = useQuery({
    queryKey: ['payment-links', page],
    queryFn: () => apiRequest<Paginated<AdminPaymentLinkListItem>>('/payment-links', { query: { page } }),
  });

  const refresh = () => qc.invalidateQueries({ queryKey: ['payment-links'] });

  return (
    <div className="content">
      {cancelTarget && <CancelModal link={cancelTarget} onSuccess={refresh} onClose={() => setCancelTarget(null)} />}
      {extendTarget && <ExtendModal link={extendTarget} onSuccess={refresh} onClose={() => setExtendTarget(null)} />}

      <OpsSectionHead title="Payment Links" sub={`${data?.total ?? 0} links`} />
      <OpsCard title={undefined} count={undefined}>
        {isLoading ? <OpsLoadingPanel label="Loading links…" size={32} /> : (
          <table>
            <thead><tr><th>Short code</th><th>Payee</th><th>Amount</th><th>Status</th><th>Uses</th><th>Expires</th><th>Actions</th></tr></thead>
            <tbody>
              {(data?.items ?? []).map((l) => (
                <tr key={l.id} onClick={() => router.push(`/payment-links/${l.id}`)} style={{ cursor: 'pointer' }}>
                  <td className="mono">{l.shortCode}</td>
                  <td style={{ maxWidth: 160, overflow: 'hidden', textOverflow: 'ellipsis' }}>{l.payeeName}</td>
                  <td>{l.amountCents ? eur(l.amountCents) : <span className="hint">open</span>}</td>
                  <td><OpsPill tone={statusPill(l.status)}>{l.status}</OpsPill></td>
                  <td className="hint">{l.useCount}{l.maxUses ? ` / ${l.maxUses}` : ''}</td>
                  <td className="hint">{l.expiresAt ? relativeTime(l.expiresAt) : '—'}</td>
                  <td onClick={(e) => e.stopPropagation()}>
                    {canAct && l.status !== 'CANCELLED' && l.status !== 'SETTLED' && (
                      <div className="row-actions">
                        <button className="mini-btn danger" onClick={() => setCancelTarget(l)}>Cancel</button>
                        <button className="mini-btn" onClick={() => setExtendTarget(l)}>Extend</button>
                      </div>
                    )}
                  </td>
                </tr>
              ))}
              {!data?.items.length && <tr><td colSpan={7}><div className="empty">No payment links found.</div></td></tr>}
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
    </div>
  );
}
