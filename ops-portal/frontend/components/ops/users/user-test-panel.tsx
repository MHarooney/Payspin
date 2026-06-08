'use client';

import {
  AdminUserDetail,
  CreatePaymentLinkAdminResult,
  Paginated,
  AdminPaymentListItem,
  UserTestSetupResult,
} from '@payspin/shared-types';
import { useMutation, useQuery } from '@tanstack/react-query';
import Link from 'next/link';
import { useState } from 'react';
import { CopyButton } from '@/components/ops/copy-button';
import { OpsCard, OpsPill } from '@/components/ops/primitives';
import { useOpsToast } from '@/components/ops/ops-toast';
import { apiRequest } from '@/lib/admin-api';
import { payerUrl, payerBaseUrl } from '@/lib/payer-url';
import { relativeTime, statusPill } from '@/lib/format';

const PRESETS = [
  { label: '€1', cents: 100 },
  { label: '€5', cents: 500 },
  { label: 'Custom', cents: 0 },
];

export function UserTestPanel({ user, onRefresh }: { user: AdminUserDetail; onRefresh: () => void }) {
  const { toast } = useOpsToast();
  const [preset, setPreset] = useState(100);
  const [customCents, setCustomCents] = useState('100');
  const [description, setDescription] = useState('Ops sandbox test');
  const [lastLink, setLastLink] = useState<CreatePaymentLinkAdminResult | null>(null);

  const amountCents = preset === 0 ? Math.max(1, parseInt(customCents, 10) || 100) : preset;

  const hasBank = user.bankAccounts.length > 0;
  const kycOk = user.kycStatus === 'VERIFIED';
  const statusOk = user.status === 'ACTIVE' && !user.isDeleted;

  const createLink = useMutation({
    mutationFn: () =>
      apiRequest<CreatePaymentLinkAdminResult>('/payment-links', {
        method: 'POST',
        body: { payeeUserId: user.id, amountCents, description },
      }),
    onSuccess: (data) => {
      setLastLink(data);
      toast('Test payment link created');
      onRefresh();
    },
    onError: (e) => toast(String((e as Error).message), 'fail'),
  });

  const quickSetup = useMutation({
    mutationFn: () =>
      apiRequest<UserTestSetupResult>(`/users/${user.id}/test-setup`, {
        method: 'POST',
        body: { amountCents, description },
      }),
    onSuccess: (data) => {
      setLastLink(data.paymentLink);
      toast('Test setup complete — KYC approved and link created');
      onRefresh();
    },
    onError: (e) => toast(String((e as Error).message), 'fail'),
  });

  const searchCode = lastLink?.shortCode ?? user.recentPaymentLinks[0]?.shortCode ?? '';
  const { data: payments } = useQuery({
    queryKey: ['test-payments', searchCode],
    queryFn: () =>
      apiRequest<Paginated<AdminPaymentListItem>>('/transactions', {
        query: { search: searchCode, page: 1, pageSize: 5 },
      }),
    enabled: searchCode.length > 0,
    refetchInterval: 10_000,
  });

  const ready = hasBank && kycOk && statusOk;

  return (
    <div className="test-panel">
      <OpsCard title="Sandbox test flow" count={undefined} style={{ marginBottom: 16 }}>
        <p className="hint" style={{ marginBottom: 16 }}>
          Uses Yapily sandbox — open the payer URL in a new tab and complete the bank step manually. Payer web:{' '}
          <span className="mono">{payerBaseUrl()}</span>
        </p>

        <h4 style={{ fontSize: 13, marginBottom: 10 }}>Prerequisites</h4>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8, marginBottom: 20 }}>
          <CheckItem ok={statusOk} label="Account active (not deleted/frozen)" />
          <CheckItem ok={kycOk} label="KYC verified" fix={!kycOk ? 'Approve KYC from the profile header' : undefined} />
          <CheckItem ok={hasBank} label="Bank account on file" fix={!hasBank ? 'User must connect a bank via mobile app' : undefined} />
        </div>

        {!ready && (
          <button className="mini-btn" disabled={quickSetup.isPending} onClick={() => quickSetup.mutate()} style={{ marginBottom: 16 }}>
            {quickSetup.isPending ? 'Setting up…' : 'Quick setup (approve KYC + create link)'}
          </button>
        )}

        <h4 style={{ fontSize: 13, marginBottom: 10 }}>Create test link</h4>
        <div className="preset-chips">
          {PRESETS.map((p) => (
            <button
              key={p.label}
              type="button"
              className={`mini-btn${preset === p.cents ? ' active' : ''}`}
              onClick={() => setPreset(p.cents)}
            >
              {p.label}
            </button>
          ))}
        </div>
        {preset === 0 && (
          <input
            className="search"
            type="number"
            min={1}
            style={{ width: 120, marginBottom: 12 }}
            value={customCents}
            onChange={(e) => setCustomCents(e.target.value)}
            placeholder="Cents"
          />
        )}
        <input
          className="search"
          style={{ width: '100%', marginBottom: 12 }}
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          placeholder="Description"
        />
        <button className="mini-btn" disabled={!hasBank || createLink.isPending} onClick={() => createLink.mutate()}>
          {createLink.isPending ? 'Creating…' : 'Create payment link'}
        </button>
      </OpsCard>

      {lastLink && (
        <OpsCard title="Latest test link" count={undefined} style={{ marginBottom: 16 }}>
          <div className="field-grid">
            <div className="field-row">
              <span className="field-label">Payer URL</span>
              <span className="mono" style={{ wordBreak: 'break-all' }}>
                {lastLink.payerUrl}
              </span>
            </div>
            <div className="field-row">
              <span className="field-label">Short code</span>
              <span className="mono">/{lastLink.shortCode}</span>
            </div>
            <div className="field-row">
              <span className="field-label">Expires</span>
              <span className="hint">{relativeTime(lastLink.expiresAt)}</span>
            </div>
          </div>
          <div style={{ display: 'flex', gap: 8, marginTop: 12, flexWrap: 'wrap' }}>
            <CopyButton value={lastLink.payerUrl} label="Copy URL" />
            <a href={lastLink.payerUrl} target="_blank" rel="noreferrer" className="mini-btn">
              Open payer page
            </a>
            <Link href={`/payment-links?search=${lastLink.shortCode}`} className="mini-btn">
              View in links
            </Link>
            <Link href={`/webhooks`} className="mini-btn">
              Webhooks
            </Link>
          </div>
        </OpsCard>
      )}

      {searchCode && (
        <OpsCard title="Payment status" count={undefined}>
          {(payments?.items ?? []).length === 0 ? (
            <div className="empty">No payments yet — complete the payer flow to see status here.</div>
          ) : (
            <table>
              <thead>
                <tr>
                  <th>Status</th>
                  <th>Amount</th>
                  <th>Initiated</th>
                </tr>
              </thead>
              <tbody>
                {(payments?.items ?? []).map((p) => (
                  <tr key={p.id}>
                    <td>
                      <OpsPill tone={statusPill(p.status)}>{p.status}</OpsPill>
                    </td>
                    <td>{(p.amountCents / 100).toFixed(2)} {p.currency}</td>
                    <td className="hint">{relativeTime(p.initiatedAt)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
          <Link href={`/transactions?search=${encodeURIComponent(searchCode)}`} className="mini-btn" style={{ marginTop: 12, display: 'inline-block' }}>
            Open in transactions
          </Link>
        </OpsCard>
      )}
    </div>
  );
}

function CheckItem({ ok, label, fix }: { ok: boolean; label: string; fix?: string }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
      <OpsPill tone={ok ? 'ok' : 'pend'}>{ok ? '✓' : '○'}</OpsPill>
      <span>{label}</span>
      {fix && <span className="hint">— {fix}</span>}
    </div>
  );
}

export function payerLinkForCode(shortCode: string) {
  return payerUrl(shortCode);
}
