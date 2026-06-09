'use client';

import {
  AdminUserDetail,
  AdminUserPresence,
  AuditEventDto,
  AdminPaymentListItem,
  AdminUserBankAccount,
  AdminUserCircleSummary,
  AdminPaymentLinkListItem,
  SupportThreadDto,
} from '@payspin/shared-types';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import Link from 'next/link';
import { use, useEffect, useState } from 'react';
import { CopyButton } from '@/components/ops/copy-button';
import { OpsLoadingPanel } from '@/components/ops/emblem-loader';
import { OpsCard, OpsPill } from '@/components/ops/primitives';
import { useOpsToast } from '@/components/ops/ops-toast';
import {
  AdminNoteEditor,
  DeleteUserModal,
  EditUserModal,
  FreezeUserModal,
  ResetPasswordModal,
} from '@/components/ops/users/user-modals';
import { UserTestPanel, payerLinkForCode } from '@/components/ops/users/user-test-panel';
import { apiRequest } from '@/lib/admin-api';
import { useAuth } from '@/lib/auth';
import { eur, relativeTime, statusPill } from '@/lib/format';

type Tab = 'overview' | 'payments' | 'links' | 'bank' | 'circles' | 'support' | 'audit' | 'devices' | 'test';

const PRESENCE_LABEL: Record<AdminUserPresence, string> = {
  online: '● Online',
  recent: '◐ Active recently',
  offline: '○ Offline',
  never: '— Never logged in',
};
const PRESENCE_TONE: Record<AdminUserPresence, string> = { online: 'ok', recent: 'pend', offline: 'blue', never: 'blue' };
const RISK_TONE: Record<string, string> = { LOW: 'ok', MEDIUM: 'pend', HIGH: 'fail' };

function OverviewTab({ user, onSaved }: { user: AdminUserDetail; onSaved: () => void }) {
  return (
    <div>
      <div className="kpis" style={{ gridTemplateColumns: 'repeat(4,1fr)', marginBottom: 20 }}>
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
        <OpsCard title="Admin State" count={undefined} style={{ marginBottom: 16 }}>
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
              <OpsPill tone={RISK_TONE[user.adminState.riskLevel] ?? 'blue'}>{user.adminState.riskLevel}</OpsPill>
            </div>
            {user.adminState.frozenReason && (
              <div className="field-row">
                <span className="field-label">Freeze reason</span>
                <span>{user.adminState.frozenReason}</span>
              </div>
            )}
          </div>
        </OpsCard>
      )}

      <AdminNoteEditor userId={user.id} initialNote={user.adminState?.note ?? null} onSaved={onSaved} />

      {user.recentPayments.length > 0 && (
        <OpsCard title="Recent Payments" count={undefined}>
          {user.recentPayments.slice(0, 5).map((p) => (
            <div key={p.id} className="activity-row">
              <div className="activity-main">
                <Link href={`/transactions?search=${encodeURIComponent(p.shortCode)}`} className="mono" style={{ fontSize: 11 }}>
                  {p.shortCode}
                </Link>
                <OpsPill tone={statusPill(p.status)}>{p.status.toLowerCase()}</OpsPill>
              </div>
              <div style={{ display: 'flex', gap: 12 }}>
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
  if (!payments.length) return <div className="empty">No payments found.</div>;
  return (
    <OpsCard title={undefined} count={undefined}>
      <table>
        <thead>
          <tr>
            <th>Code</th>
            <th>Amount</th>
            <th>Status</th>
            <th>Payer Bank</th>
            <th>Initiated</th>
          </tr>
        </thead>
        <tbody>
          {payments.map((p) => (
            <tr key={p.id}>
              <td>
                <Link href={`/transactions?search=${encodeURIComponent(p.shortCode)}`} className="mono">
                  {p.shortCode}
                </Link>
              </td>
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

function LinksTab({ links }: { links: AdminPaymentLinkListItem[] }) {
  if (!links.length) return <div className="empty">No payment links.</div>;
  return (
    <OpsCard title={undefined} count={undefined}>
      <table>
        <thead>
          <tr>
            <th>Code</th>
            <th>Amount</th>
            <th>Status</th>
            <th>Uses</th>
            <th>Expires</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {links.map((l) => {
            const url = payerLinkForCode(l.shortCode);
            return (
              <tr key={l.id}>
                <td className="mono">{l.shortCode}</td>
                <td>{l.amountCents ? eur(l.amountCents) : 'open'}</td>
                <td>
                  <OpsPill tone={statusPill(l.status)}>{l.status}</OpsPill>
                </td>
                <td className="hint">
                  {l.useCount}
                  {l.maxUses ? ` / ${l.maxUses}` : ''}
                </td>
                <td className="hint">{l.expiresAt ? relativeTime(l.expiresAt) : '—'}</td>
                <td>
                  <div className="row-actions">
                    <CopyButton value={url} label="Copy" />
                    <a href={url} target="_blank" rel="noreferrer" className="mini-btn">
                      Open
                    </a>
                    <Link href={`/payment-links?search=${l.shortCode}`} className="mini-btn">
                      Details
                    </Link>
                  </div>
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </OpsCard>
  );
}

function BankTab({ accounts }: { accounts: AdminUserBankAccount[] }) {
  if (!accounts.length) return <div className="empty">No bank accounts.</div>;
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
              <span className="field-label">Holder</span>
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
  if (!circles.length) return <div className="empty">No circles.</div>;
  return (
    <OpsCard title={undefined} count={undefined}>
      <table>
        <thead>
          <tr>
            <th>Circle</th>
            <th>Role</th>
            <th>Status</th>
            <th>Payout</th>
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
              <td className="hint">{c.payoutOrder ?? '—'}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </OpsCard>
  );
}

function SupportTab({ userId }: { userId: string }) {
  const { data, isLoading } = useQuery({
    queryKey: ['user-support', userId],
    queryFn: () => apiRequest<SupportThreadDto[]>(`/users/${userId}/support-threads`),
  });
  if (isLoading) return <div className="empty">Loading support threads…</div>;
  if (!data || data.length === 0) return <div className="empty">No support threads for this user.</div>;
  return (
    <OpsCard title={undefined} count={undefined}>
      <table>
        <thead>
          <tr>
            <th>Subject</th>
            <th>Category</th>
            <th>Status</th>
            <th>Last message</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          {data.map((t) => (
            <tr key={t.id}>
              <td>{t.subjectName}</td>
              <td className="hint">{t.category ?? '—'}</td>
              <td>
                <OpsPill tone={t.status === 'RESOLVED' ? 'ok' : 'pend'}>{t.status}</OpsPill>
                {t.unread && <OpsPill tone="accent">unread</OpsPill>}
              </td>
              <td className="hint">{relativeTime(t.lastMessageAt)}</td>
              <td>
                <Link href={`/messages?thread=${t.id}`} className="mini-btn">
                  Open
                </Link>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </OpsCard>
  );
}

function AuditTab({ events }: { events: AuditEventDto[] }) {
  if (!events.length) return <div className="empty">No audit events for this user.</div>;
  return (
    <OpsCard title={undefined} count={undefined}>
      <table>
        <thead>
          <tr>
            <th>Action</th>
            <th>By</th>
            <th>When</th>
          </tr>
        </thead>
        <tbody>
          {events.map((e) => (
            <tr key={e.id}>
              <td>
                <span className="mono" style={{ fontSize: 11 }}>
                  {e.action}
                </span>
              </td>
              <td className="hint">{e.adminEmail}</td>
              <td className="hint">{relativeTime(e.createdAt)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </OpsCard>
  );
}

export default function UserDetailPage({
  params,
  searchParams,
}: {
  params: Promise<{ id: string }>;
  searchParams: Promise<{ tab?: string }>;
}) {
  const { id } = use(params);
  const sp = use(searchParams);
  const qc = useQueryClient();
  const { admin } = useAuth();
  const { toast } = useOpsToast();
  const canAct = admin?.role === 'SUPER_ADMIN' || admin?.role === 'OPS';
  const isSuperAdmin = admin?.role === 'SUPER_ADMIN';
  const [tab, setTab] = useState<Tab>((sp.tab as Tab) || 'overview');
  const [modal, setModal] = useState<'freeze' | 'edit' | 'delete' | 'reset-password' | null>(null);

  useEffect(() => {
    if (sp.tab === 'test') setTab('test');
  }, [sp.tab]);

  const { data: user, isLoading } = useQuery({
    queryKey: ['user-detail', id],
    queryFn: () => apiRequest<AdminUserDetail>(`/users/${id}`),
  });

  const setState = useMutation({
    mutationFn: (body: Record<string, unknown>) => apiRequest(`/users/${id}/state`, { method: 'POST', body }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['user-detail', id] });
      qc.invalidateQueries({ queryKey: ['users'] });
      toast('User state updated');
    },
    onError: (e) => toast(String((e as Error).message), 'fail'),
  });

  const refresh = () => qc.invalidateQueries({ queryKey: ['user-detail', id] });

  if (isLoading || !user) return <div className="content"><OpsLoadingPanel label="Loading user profile…" size={36} /></div>;

  const isFrozen = user.status === 'FROZEN';
  const canTest = canAct && !user.isDeleted && user.bankAccounts.length > 0;

  const TABS: { key: Tab; label: string }[] = [
    { key: 'overview', label: 'Overview' },
    { key: 'test', label: 'Test' },
    { key: 'payments', label: `Payments (${user.recentPayments.length})` },
    { key: 'links', label: `Links (${user.recentPaymentLinks.length})` },
    { key: 'bank', label: `Bank (${user.bankAccounts.length})` },
    { key: 'circles', label: `Circles (${user.circles.length})` },
    { key: 'support', label: 'Support' },
    { key: 'audit', label: `Audit (${user.auditEvents.length})` },
    { key: 'devices', label: `Devices (${user.registeredDeviceCount})` },
  ];

  return (
    <div className="content">
      {modal === 'freeze' && (
        <FreezeUserModal
          userLabel={user.displayName ?? user.email}
          onConfirm={(reason) => { setState.mutate({ status: 'FROZEN', reason }); setModal(null); }}
          onClose={() => setModal(null)}
        />
      )}
      {modal === 'edit' && (
        <EditUserModal user={user} isSuperAdmin={isSuperAdmin} onSuccess={() => { refresh(); toast('Profile updated'); }} onClose={() => setModal(null)} />
      )}
      {modal === 'delete' && (
        <DeleteUserModal user={user} onSuccess={() => { qc.invalidateQueries({ queryKey: ['users'] }); toast('User deleted'); }} onClose={() => setModal(null)} />
      )}
      {modal === 'reset-password' && (
        <ResetPasswordModal userId={id} onClose={() => setModal(null)} onSuccess={() => toast('Password reset')} />
      )}

      <div style={{ marginBottom: 4 }}>
        <Link href="/users" className="back-link">
          ← Users
        </Link>
      </div>

      <OpsCard title={undefined} count={undefined} className="user-hero">
        <div className="user-hero-inner">
          <div className="avatar" style={{ width: 48, height: 48, fontSize: 16 }}>
            {(user.displayName ?? user.email)
              .split(' ')
              .map((w) => w[0])
              .slice(0, 2)
              .join('')
              .toUpperCase()}
          </div>
          <div className="user-hero-info">
            <h2 style={{ fontSize: 20, fontWeight: 700 }}>{user.displayName ?? '(no name)'}</h2>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <span className="mono" style={{ color: 'var(--muted)', fontSize: 13 }}>
                {user.email}
              </span>
              <CopyButton value={user.email} label="Copy email" />
            </div>
            {user.phoneE164 && <div style={{ color: 'var(--muted)', fontSize: 12 }}>{user.phoneE164}</div>}
            <div style={{ display: 'flex', gap: 8, marginTop: 8, flexWrap: 'wrap' }}>
              <OpsPill tone={statusPill(user.status)}>{user.status}</OpsPill>
              <OpsPill tone={statusPill(user.kycStatus)}>
                {user.kycTier ? `${user.kycTier} ` : ''}KYC {user.kycStatus.toLowerCase()}
              </OpsPill>
              <OpsPill tone={PRESENCE_TONE[user.presence]}>{PRESENCE_LABEL[user.presence]}</OpsPill>
              {user.isDeleted && <OpsPill tone="fail">DELETED</OpsPill>}
            </div>
            <div className="hint" style={{ marginTop: 6, fontSize: 11 }}>
              Member since {new Date(user.createdAt).toLocaleDateString()} ·
              {user.lastLoginAt ? ` Last login ${relativeTime(user.lastLoginAt)}` : ' Never logged in'} ·
              {user.registeredDeviceCount} device{user.registeredDeviceCount !== 1 ? 's' : ''}
            </div>
          </div>
          {canAct && !user.isDeleted && (
            <div className="user-hero-actions">
              <div className="action-group">
                {canTest && (
                  <button className="mini-btn" style={{ borderColor: 'var(--accent-2)' }} onClick={() => setTab('test')}>
                    Create test link
                  </button>
                )}
                <button className="mini-btn" onClick={() => setModal('edit')}>
                  Edit
                </button>
                {user.kycStatus !== 'VERIFIED' && (
                  <button className="mini-btn" onClick={() => setState.mutate({ kycStatus: 'VERIFIED' })}>
                    Approve KYC
                  </button>
                )}
                {isFrozen ? (
                  <button className="mini-btn" onClick={() => setState.mutate({ status: 'ACTIVE' })}>
                    Unfreeze
                  </button>
                ) : (
                  <button className="mini-btn danger" onClick={() => setModal('freeze')}>
                    Freeze
                  </button>
                )}
                <button className="mini-btn" onClick={() => setModal('reset-password')}>
                  Reset password
                </button>
              </div>
              {isSuperAdmin && (
                <div className="action-group action-group-danger">
                  <button className="mini-btn danger" onClick={() => setModal('delete')}>
                    Delete
                  </button>
                </div>
              )}
            </div>
          )}
          {user.isDeleted && <p className="hint">This account is soft-deleted — actions are disabled.</p>}
        </div>
      </OpsCard>

      <div className="seg" style={{ marginTop: 16, marginBottom: 16 }}>
        {TABS.map((t) => (
          <button key={t.key} className={tab === t.key ? 'active' : ''} onClick={() => setTab(t.key)}>
            {t.label}
          </button>
        ))}
      </div>

      {tab === 'overview' && <OverviewTab user={user} onSaved={() => { refresh(); toast('Note saved'); }} />}
      {tab === 'test' && <UserTestPanel user={user} onRefresh={refresh} />}
      {tab === 'payments' && <PaymentsTab payments={user.recentPayments} />}
      {tab === 'links' && <LinksTab links={user.recentPaymentLinks} />}
      {tab === 'bank' && <BankTab accounts={user.bankAccounts} />}
      {tab === 'circles' && <CirclesTab circles={user.circles} />}
      {tab === 'support' && <SupportTab userId={id} />}
      {tab === 'audit' && <AuditTab events={user.auditEvents} />}
      {tab === 'devices' && (
        <OpsCard title="Registered devices" count={undefined}>
          {user.devices.length === 0 ? (
            <div className="empty">No devices registered.</div>
          ) : (
            <table>
              <thead>
                <tr>
                  <th>Platform</th>
                  <th>Last active</th>
                </tr>
              </thead>
              <tbody>
                {user.devices.map((d) => (
                  <tr key={d.id}>
                    <td>{d.platform}</td>
                    <td className="hint">{relativeTime(d.lastUpdatedAt)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </OpsCard>
      )}
    </div>
  );
}
