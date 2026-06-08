'use client';

import {
  AdminUserDetail,
  AdminPaymentListItem,
  AdminUserBankAccount,
  AdminUserCircleSummary,
} from '@payspin/shared-types';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import Link from 'next/link';
import { use, useState } from 'react';
import { OpsLoadingPanel } from '@/components/ops/emblem-loader';
import { OpsCard, OpsPill, OpsSectionHead } from '@/components/ops/primitives';
import { apiRequest } from '@/lib/admin-api';
import { useAuth } from '@/lib/auth';
import { eur, relativeTime, statusPill } from '@/lib/format';

type Tab = 'overview' | 'payments' | 'links' | 'bank' | 'circles';

const RISK_TONE: Record<string, string> = { LOW: 'ok', MEDIUM: 'pend', HIGH: 'fail' };

function UserAvatar({ name }: { name: string }) {
  const initials = name
    .split(' ')
    .map((w) => w[0])
    .slice(0, 2)
    .join('')
    .toUpperCase();
  return <div className="avatar" style={{ width: 48, height: 48, fontSize: 16 }}>{initials}</div>;
}

function FreezeModal({
  userName,
  onConfirm,
  onClose,
}: {
  userName: string;
  onConfirm: (reason: string) => void;
  onClose: () => void;
}) {
  const [reason, setReason] = useState('');
  return (
    <div className="modal-backdrop">
      <div className="modal" style={{ maxWidth: 440 }}>
        <h3 style={{ marginBottom: 12 }}>Freeze account</h3>
        <p style={{ color: 'var(--muted)', marginBottom: 16, fontSize: 13 }}>
          You are freezing <strong>{userName}</strong>. This will prevent them from making
          or receiving payments until unfrozen.
        </p>
        <label style={{ display: 'block', marginBottom: 8, fontSize: 12, color: 'var(--muted)' }}>
          Reason (required)
        </label>
        <textarea
          className="search"
          style={{ width: '100%', minHeight: 80, resize: 'vertical', marginBottom: 16 }}
          placeholder="Enter reason for freezing this account…"
          value={reason}
          onChange={(e) => setReason(e.target.value)}
        />
        <div style={{ display: 'flex', gap: 10, justifyContent: 'flex-end' }}>
          <button className="mini-btn" onClick={onClose}>
            Cancel
          </button>
          <button
            className="mini-btn danger"
            disabled={reason.trim().length < 3}
            onClick={() => reason.trim().length >= 3 && onConfirm(reason.trim())}
          >
            Freeze account
          </button>
        </div>
      </div>
    </div>
  );
}

function OverviewTab({ user }: { user: AdminUserDetail }) {
  return (
    <div className="user-detail-overview">
      <div className="kpis" style={{ gridTemplateColumns: 'repeat(4, 1fr)', marginBottom: 20 }}>
        {[
          { label: 'Lifetime Volume', value: eur(user.lifetimeVolumeCents) },
          { label: 'Payments', value: String(user.paymentCount) },
          { label: 'Payment Links', value: String(user.paymentLinkCount) },
          { label: 'Bank Accounts', value: String(user.bankAccounts.length) },
        ].map((k) => (
          <div className="kpi" key={k.label}>
            <div className="label">{k.label}</div>
            <div className="val">{k.value}</div>
          </div>
        ))}
      </div>

      {user.adminState && (
        <OpsCard title="Admin State" count={undefined}>
          <div className="field-grid">
            <div className="field-row">
              <span className="field-label">Status</span>
              <OpsPill tone={statusPill(user.adminState.status)}>{user.adminState.status}</OpsPill>
            </div>
            <div className="field-row">
              <span className="field-label">KYC</span>
              <OpsPill tone={statusPill(user.adminState.kycStatus)}>
                {user.adminState.kycTier ? `${user.adminState.kycTier} · ` : ''}
                {user.adminState.kycStatus}
              </OpsPill>
            </div>
            <div className="field-row">
              <span className="field-label">Risk</span>
              <OpsPill tone={RISK_TONE[user.adminState.riskLevel] ?? 'blue'}>
                {user.adminState.riskLevel}
              </OpsPill>
            </div>
            {user.adminState.frozenReason && (
              <div className="field-row">
                <span className="field-label">Freeze reason</span>
                <span>{user.adminState.frozenReason}</span>
              </div>
            )}
            {user.adminState.updatedByEmail && (
              <div className="field-row">
                <span className="field-label">Last updated by</span>
                <span className="mono">{user.adminState.updatedByEmail}</span>
              </div>
            )}
          </div>
        </OpsCard>
      )}

      {user.recentPayments.length > 0 && (
        <OpsCard title="Recent Activity" count={undefined} style={{ marginTop: 16 }}>
          {user.recentPayments.slice(0, 5).map((p) => (
            <div key={p.id} className="activity-row">
              <div className="activity-main">
                <span className="mono" style={{ fontSize: 11 }}>
                  {p.shortCode}
                </span>
                <OpsPill tone={statusPill(p.status)}>{p.status.toLowerCase()}</OpsPill>
              </div>
              <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
                <strong>{eur(p.amountCents)}</strong>
                <span className="hint">{relativeTime(p.initiatedAt)}</span>
              </div>
            </div>
          ))}
        </OpsCard>
      )}
    </div>
  );
}

function PaymentsTab({ payments }: { payments: AdminPaymentListItem[] }) {
  if (!payments.length)
    return <div className="empty">No payments found.</div>;
  return (
    <OpsCard title={undefined} count={undefined}>
      <table>
        <thead>
          <tr>
            <th>Short Code</th>
            <th>Amount</th>
            <th>Status</th>
            <th>Payer Bank</th>
            <th>Initiated</th>
          </tr>
        </thead>
        <tbody>
          {payments.map((p) => (
            <tr key={p.id}>
              <td className="mono">{p.shortCode}</td>
              <td>{eur(p.amountCents)}</td>
              <td>
                <OpsPill tone={statusPill(p.status)}>{p.status}</OpsPill>
              </td>
              <td>{p.payerBankName ?? '—'}</td>
              <td className="hint">{relativeTime(p.initiatedAt)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </OpsCard>
  );
}

function BankTab({ accounts }: { accounts: AdminUserBankAccount[] }) {
  if (!accounts.length)
    return <div className="empty">No bank accounts linked.</div>;
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
      {accounts.map((b) => (
        <OpsCard key={b.id} title={b.bankName ?? 'Unknown Bank'} count={undefined}>
          <div className="field-grid">
            <div className="field-row">
              <span className="field-label">IBAN</span>
              <span className="mono">···· {b.ibanLast4}</span>
            </div>
            <div className="field-row">
              <span className="field-label">Account holder</span>
              <span>{b.accountHolder}</span>
            </div>
            <div className="field-row">
              <span className="field-label">Verified</span>
              <OpsPill tone={b.verified ? 'ok' : 'pend'}>{b.verified ? 'Verified' : 'Unverified'}</OpsPill>
            </div>
            <div className="field-row">
              <span className="field-label">Primary</span>
              {b.isPrimary ? <OpsPill tone="blue">Primary</OpsPill> : <span className="hint">—</span>}
            </div>
          </div>
        </OpsCard>
      ))}
    </div>
  );
}

function CirclesTab({ circles }: { circles: AdminUserCircleSummary[] }) {
  if (!circles.length)
    return <div className="empty">Not a member of any circles.</div>;
  return (
    <OpsCard title={undefined} count={undefined}>
      <table>
        <thead>
          <tr>
            <th>Circle</th>
            <th>Role</th>
            <th>Status</th>
            <th>Payout Order</th>
          </tr>
        </thead>
        <tbody>
          {circles.map((c) => (
            <tr key={c.id}>
              <td>{c.name}</td>
              <td>
                <OpsPill tone={c.role === 'host' ? 'accent' : 'blue'}>{c.role}</OpsPill>
              </td>
              <td>
                <OpsPill tone={statusPill(c.status)}>{c.status}</OpsPill>
              </td>
              <td>{c.payoutOrder ?? '—'}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </OpsCard>
  );
}

export default function UserDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const qc = useQueryClient();
  const { admin } = useAuth();
  const canAct = admin?.role === 'SUPER_ADMIN' || admin?.role === 'OPS';
  const [tab, setTab] = useState<Tab>('overview');
  const [showFreezeModal, setShowFreezeModal] = useState(false);

  const { data: user, isLoading } = useQuery({
    queryKey: ['user-detail', id],
    queryFn: () => apiRequest<AdminUserDetail>(`/users/${id}`),
  });

  const setState = useMutation({
    mutationFn: (body: Record<string, unknown>) =>
      apiRequest(`/users/${id}/state`, { method: 'POST', body }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['user-detail', id] });
      qc.invalidateQueries({ queryKey: ['users'] });
      qc.invalidateQueries({ queryKey: ['audit'] });
    },
  });

  if (isLoading || !user) {
    return (
      <div className="content">
        <OpsLoadingPanel label="Loading user profile…" size={36} />
      </div>
    );
  }

  const tabs: { key: Tab; label: string }[] = [
    { key: 'overview', label: 'Overview' },
    { key: 'payments', label: `Payments (${user.recentPayments.length})` },
    { key: 'bank', label: `Bank (${user.bankAccounts.length})` },
    { key: 'circles', label: `Circles (${user.circles.length})` },
  ];

  const isFrozen = user.status === 'FROZEN';

  return (
    <div className="content">
      {showFreezeModal && (
        <FreezeModal
          userName={user.displayName ?? user.email}
          onConfirm={(reason) => {
            setState.mutate({ status: 'FROZEN', reason });
            setShowFreezeModal(false);
          }}
          onClose={() => setShowFreezeModal(false)}
        />
      )}

      <div style={{ marginBottom: 4 }}>
        <Link href="/users" className="back-link">
          ← Users
        </Link>
      </div>

      {/* Hero header */}
      <OpsCard title={undefined} count={undefined} className="user-hero">
        <div className="user-hero-inner">
          <UserAvatar name={user.displayName ?? user.email} />
          <div className="user-hero-info">
            <h2 style={{ fontSize: 20, fontWeight: 700 }}>{user.displayName ?? '(no name)'}</h2>
            <div className="mono" style={{ color: 'var(--muted)', fontSize: 13 }}>
              {user.email}
            </div>
            {user.phoneE164 && (
              <div style={{ color: 'var(--muted)', fontSize: 12 }}>{user.phoneE164}</div>
            )}
            <div style={{ display: 'flex', gap: 8, marginTop: 8, flexWrap: 'wrap' }}>
              <OpsPill tone={statusPill(user.status)}>{user.status}</OpsPill>
              <OpsPill tone={statusPill(user.kycStatus)}>
                {user.kycTier ? `${user.kycTier} ` : ''}KYC {user.kycStatus.toLowerCase()}
              </OpsPill>
              <OpsPill tone={RISK_TONE[user.riskLevel] ?? 'blue'}>risk: {user.riskLevel}</OpsPill>
              {user.bankVerified && <OpsPill tone="ok">bank verified</OpsPill>}
              {user.phoneVerified && <OpsPill tone="ok">phone verified</OpsPill>}
            </div>
          </div>
          {canAct && (
            <div className="user-hero-actions">
              {user.kycStatus !== 'VERIFIED' && (
                <button
                  className="mini-btn"
                  onClick={() => setState.mutate({ kycStatus: 'VERIFIED' })}
                  disabled={setState.isPending}
                >
                  Approve KYC
                </button>
              )}
              {isFrozen ? (
                <button
                  className="mini-btn"
                  onClick={() => setState.mutate({ status: 'ACTIVE' })}
                  disabled={setState.isPending}
                >
                  Unfreeze
                </button>
              ) : (
                <button
                  className="mini-btn danger"
                  onClick={() => setShowFreezeModal(true)}
                  disabled={setState.isPending}
                >
                  Freeze
                </button>
              )}
            </div>
          )}
        </div>
        <div className="hint" style={{ marginTop: 8, fontSize: 11 }}>
          Member since {new Date(user.createdAt).toLocaleDateString()}
        </div>
      </OpsCard>

      {/* Tabs */}
      <div className="seg" style={{ marginTop: 16, marginBottom: 16 }}>
        {tabs.map((t) => (
          <button
            key={t.key}
            className={tab === t.key ? 'active' : ''}
            onClick={() => setTab(t.key)}
          >
            {t.label}
          </button>
        ))}
      </div>

      {tab === 'overview' && <OverviewTab user={user} />}
      {tab === 'payments' && <PaymentsTab payments={user.recentPayments} />}
      {tab === 'bank' && <BankTab accounts={user.bankAccounts} />}
      {tab === 'circles' && <CirclesTab circles={user.circles} />}
    </div>
  );
}
