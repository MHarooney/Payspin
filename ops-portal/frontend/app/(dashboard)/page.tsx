'use client';

import {
  AdminPaymentListItem,
  DashboardKpis,
  DashboardPeriod,
  OpenAlert,
  Paginated,
  VolumeSeries,
} from '@payspin/shared-types';
import { useQuery } from '@tanstack/react-query';
import { useState } from 'react';
import { BarChart, C } from '@/components/ops/charts';
import { OpsLoadingPanel } from '@/components/ops/emblem-loader';
import { OpsCard, OpsKpiStrip, OpsPill, OpsSectionHead, OpsSegment } from '@/components/ops/primitives';
import { apiRequest } from '@/lib/admin-api';
import { eur, relativeTime } from '@/lib/format';

const SEVERITY_TONE: Record<OpenAlert['severity'], string> = { HIGH: 'fail', MEDIUM: 'pend', LOW: 'blue' };

export default function DashboardPage() {
  const [period, setPeriod] = useState<DashboardPeriod>('today');

  const kpis = useQuery({
    queryKey: ['dashboard-kpis', period],
    queryFn: () => apiRequest<DashboardKpis>('/dashboard/kpis', { query: { period } }),
  });
  const volume = useQuery({
    queryKey: ['dashboard-volume', period],
    queryFn: () => apiRequest<VolumeSeries>('/dashboard/volume', { query: { period } }),
  });
  const alerts = useQuery({
    queryKey: ['dashboard-alerts'],
    queryFn: () => apiRequest<OpenAlert[]>('/dashboard/alerts'),
  });
  const feed = useQuery({
    queryKey: ['live-feed'],
    queryFn: () =>
      apiRequest<Paginated<AdminPaymentListItem>>('/transactions', { query: { pageSize: 8 } }),
    refetchInterval: 8000,
  });

  return (
    <>
      <OpsSectionHead title="Platform overview" sub="Snapshot across the period you select">
        <OpsSegment
          value={period}
          onChange={setPeriod}
          options={[
            { value: 'today', label: 'Today' },
            { value: 'week', label: 'This week' },
            { value: 'month', label: 'This month' },
          ]}
        />
      </OpsSectionHead>

      {kpis.data ? (
        <OpsKpiStrip kpis={kpis.data.kpis} />
      ) : (
        <OpsLoadingPanel label="Loading dashboard metrics" size={36} />
      )}

      <div className="grid-2">
        <OpsCard title="Transaction volume">
          <div className="chart-box">
            {volume.data ? (
              <BarChart
                data={{
                  labels: volume.data.points.map((p) => p.label),
                  datasets: [
                    {
                      label: 'Volume €',
                      data: volume.data.points.map((p) => p.volumeCents / 100),
                      backgroundColor: C.accent + 'cc',
                      borderRadius: 4,
                    },
                  ],
                }}
              />
            ) : (
              <OpsLoadingPanel label="Loading volume chart" size={36} />
            )}
          </div>
        </OpsCard>

        <OpsCard
          title="Open alerts"
          count={<span className="count">{alerts.data?.length ?? 0} active</span>}
        >
          <div className="feed">
            {alerts.data && alerts.data.length > 0 ? (
              alerts.data.map((a) => (
                <div className="feed-row" key={a.id}>
                  <div
                    className="feed-ico"
                    style={{ background: 'var(--red-dim)', color: 'var(--red)' }}
                  >
                    ⚠
                  </div>
                  <div className="who">
                    <b>{a.title}</b>
                    <br />
                    <span>{a.detail}</span>
                  </div>
                  <OpsPill tone={SEVERITY_TONE[a.severity]}>{a.severity}</OpsPill>
                </div>
              ))
            ) : (
              <div className="empty">No open alerts.</div>
            )}
          </div>
        </OpsCard>
      </div>

      <OpsCard
        title="Live transaction feed"
        count={<OpsPill tone="ok">● live</OpsPill>}
      >
        <div className="feed">
          {feed.data && feed.data.items.length > 0 ? (
            feed.data.items.map((t) => {
              const ok = t.status === 'COMPLETED';
              const failed = t.status === 'FAILED' || t.status === 'CANCELLED';
              return (
                <div className="feed-row" key={t.id}>
                  <div
                    className="feed-ico"
                    style={{
                      background: failed ? 'var(--red-dim)' : ok ? 'var(--accent-dim)' : 'var(--amber-dim)',
                      color: failed ? 'var(--red)' : ok ? 'var(--accent)' : 'var(--amber)',
                    }}
                  >
                    {ok ? '✓' : failed ? '✕' : '…'}
                  </div>
                  <div className="who">
                    <b>→ {t.payeeName}</b>
                    <br />
                    <span>
                      {t.payerBankName ?? 'Bank payment'} · {relativeTime(t.initiatedAt)}
                    </span>
                  </div>
                  <div className="amt">{eur(t.amountCents)}</div>
                  <OpsPill tone={ok ? 'ok' : failed ? 'fail' : 'pend'}>
                    {t.status.replace(/_/g, ' ').toLowerCase()}
                  </OpsPill>
                </div>
              );
            })
          ) : (
            <div className="empty">No transactions yet. Create a payment in the consumer app to see it here.</div>
          )}
        </div>
      </OpsCard>
    </>
  );
}
