'use client';

import { ReportGranularity, ReportSection, ReportsResponse } from '@payspin/shared-types';
import { useQuery } from '@tanstack/react-query';
import { useState } from 'react';
import { BarChart, C, DoughnutChart, LineChart, line } from '@/components/ops/charts';
import { OpsCard, OpsKpiStrip, OpsSectionHead } from '@/components/ops/primitives';
import { apiRequest } from '@/lib/admin-api';

const TABS: { value: ReportGranularity; label: string }[] = [
  { value: 'hourly', label: 'Hourly' },
  { value: 'daily', label: 'Daily' },
  { value: 'weekly', label: 'Weekly' },
  { value: 'monthly', label: 'Monthly' },
];

export default function ReportsPage() {
  const [granularity, setGranularity] = useState<ReportGranularity>('hourly');
  const { data } = useQuery({
    queryKey: ['reports', granularity],
    queryFn: () => apiRequest<ReportsResponse>('/reports', { query: { granularity } }),
  });

  const byId = (id: string): ReportSection | undefined => data?.sections.find((s) => s.id === id);
  const labels = (s?: ReportSection) => s?.series.map((p) => p.label) ?? [];
  const vals = (s: ReportSection | undefined, key: string) => s?.series.map((p) => p.values[key] ?? 0) ?? [];

  const traffic = byId('traffic');
  const failures = byId('failures');
  const providers = byId('providers');
  const security = byId('security');
  const growth = byId('growth');
  const settlement = byId('settlement');
  const revenue = byId('revenue');

  return (
    <>
      <OpsSectionHead
        title="Detailed reports"
        sub="Granularity tabs · per-view KPIs"
        preview={data?.preview}
      />
      <div className="tabs">
        {TABS.map((t) => (
          <div
            key={t.value}
            className={`tab${granularity === t.value ? ' active' : ''}`}
            onClick={() => setGranularity(t.value)}
          >
            {t.label}
          </div>
        ))}
      </div>

      <OpsCard title="① Traffic volume & success rate">
        {traffic && <OpsKpiStrip kpis={traffic.kpis} columns={traffic.kpis.length} />}
        <div className="chart-box lg">
          <BarChart
            data={{
              labels: labels(traffic),
              datasets: [
                { label: 'Transactions', data: vals(traffic, 'transactions'), backgroundColor: C.accent + 'cc', borderRadius: 4, yAxisID: 'y' },
                {
                  type: 'line' as const,
                  label: 'Success rate %',
                  data: vals(traffic, 'successRate'),
                  borderColor: C.brand,
                  borderWidth: 2,
                  pointRadius: 0,
                  tension: 0.35,
                  yAxisID: 'y1',
                } as never,
              ],
            }}
            options={{
              responsive: true,
              maintainAspectRatio: false,
              plugins: { legend: { display: true, position: 'bottom' } },
              scales: {
                y: { position: 'left', beginAtZero: true },
                y1: { position: 'right', min: 90, max: 100, grid: { drawOnChartArea: false } },
              },
            }}
          />
        </div>
      </OpsCard>

      <div className="grid-2">
        <OpsCard title="② Failures by reason">
          <div className="chart-box">
            <DoughnutChart
              data={{
                labels: labels(failures),
                datasets: [
                  { data: vals(failures, 'share'), backgroundColor: [C.red, C.amber, C.blue, C.purple], borderWidth: 0 },
                ],
              }}
            />
          </div>
        </OpsCard>
        <OpsCard title="③ Provider performance">
          <div className="chart-box">
            <LineChart
              legend
              data={{
                labels: labels(providers),
                datasets: [
                  line('Yapily success %', vals(providers, 'yapily'), C.accent, false),
                  line('Avg latency ms', vals(providers, 'latencyMs'), C.amber, false),
                ],
              }}
            />
          </div>
        </OpsCard>
      </div>

      <div className="grid-2">
        <OpsCard title="④ Security & risk alerts">
          {security && <OpsKpiStrip kpis={security.kpis} columns={2} />}
          <div className="chart-box sm">
            <BarChart
              data={{
                labels: labels(security),
                datasets: [
                  { label: 'High', data: vals(security, 'high'), backgroundColor: C.red, borderRadius: 3, stack: 'a' },
                  { label: 'Medium', data: vals(security, 'medium'), backgroundColor: C.amber, borderRadius: 3, stack: 'a' },
                  { label: 'Low', data: vals(security, 'low'), backgroundColor: C.blue, borderRadius: 3, stack: 'a' },
                ],
              }}
              options={{
                responsive: true,
                maintainAspectRatio: false,
                plugins: { legend: { display: true, position: 'bottom' } },
                scales: { x: { stacked: true }, y: { stacked: true } },
              }}
            />
          </div>
        </OpsCard>
        <OpsCard title="⑤ User growth & engagement">
          {growth && <OpsKpiStrip kpis={growth.kpis} columns={2} />}
          <div className="chart-box sm">
            <LineChart
              legend
              data={{
                labels: labels(growth),
                datasets: [line('New signups', vals(growth, 'signups'), C.brand), line('Active users', vals(growth, 'active'), C.accent)],
              }}
            />
          </div>
        </OpsCard>
      </div>

      <div className="grid-2">
        <OpsCard title="⑥ Settlement & float">
          <div className="chart-box">
            <BarChart
              data={{
                labels: labels(settlement),
                datasets: [
                  { label: 'Settled', data: vals(settlement, 'settled'), backgroundColor: C.accent + 'cc', borderRadius: 4 },
                  { label: 'Awaiting bank', data: vals(settlement, 'awaiting'), backgroundColor: C.amber + 'cc', borderRadius: 4 },
                ],
              }}
              options={{
                responsive: true,
                maintainAspectRatio: false,
                plugins: { legend: { display: true, position: 'bottom' } },
                scales: { y: { beginAtZero: true } },
              }}
            />
          </div>
        </OpsCard>
        <OpsCard title="⑦ Revenue & fees">
          {revenue && <OpsKpiStrip kpis={revenue.kpis} columns={2} />}
          <div className="chart-box sm">
            <LineChart data={{ labels: labels(revenue), datasets: [line('Fee revenue €', vals(revenue, 'feeRevenue'), C.accent)] }} />
          </div>
        </OpsCard>
      </div>
    </>
  );
}
