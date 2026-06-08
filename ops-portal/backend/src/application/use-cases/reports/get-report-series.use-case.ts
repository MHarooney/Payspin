import { Injectable } from '@nestjs/common';
import { ReportGranularity, ReportSection, ReportsResponse } from '@payspin/shared-types';
import { reportsQuerySchema } from '@payspin/validators';

const LABELS: Record<ReportGranularity, string[]> = {
  hourly: Array.from({ length: 24 }, (_, i) => `${i}:00`),
  daily: Array.from({ length: 30 }, (_, i) => `D${i + 1}`),
  weekly: Array.from({ length: 12 }, (_, i) => `W${i + 1}`),
  monthly: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
};

/** Deterministic pseudo-random so report charts are stable between requests. */
function seeded(seed: number): () => number {
  let s = seed % 2147483647;
  if (s <= 0) s += 2147483646;
  return () => {
    s = (s * 16807) % 2147483647;
    return s / 2147483647;
  };
}

/**
 * Phase 2: report series are synthesized deterministically from the granularity
 * (marked preview) until time-bucketed materialized queries are wired. UI is
 * complete; swap the generators for SQL aggregates to go live.
 */
@Injectable()
export class GetReportSeriesUseCase {
  execute(query: unknown): ReportsResponse {
    const { granularity } = reportsQuerySchema.parse(query);
    const labels = LABELS[granularity as ReportGranularity];
    const rnd = seeded(granularity.length * 7 + labels.length);
    const span = (min: number, max: number) => Math.round(min + rnd() * (max - min));

    const sections: ReportSection[] = [
      {
        id: 'traffic',
        title: 'Traffic volume & success rate',
        series: labels.map((label) => ({
          label,
          values: { transactions: span(400, 1600), successRate: span(95, 99) },
        })),
        kpis: [
          { label: 'Total Tx', value: span(8000, 40000).toLocaleString(), trend: '▲ 8.1%', direction: 'up' },
          { label: 'Success Rate', value: `${span(96, 99)}.4%`, trend: '▼ 0.4%', direction: 'down' },
        ],
      },
      {
        id: 'failures',
        title: 'Failures by reason',
        series: [
          { label: 'Insufficient funds', values: { share: 38 } },
          { label: 'Consent expired', values: { share: 27 } },
          { label: 'SCA abandoned', values: { share: 21 } },
          { label: 'Timeout / downtime', values: { share: 14 } },
        ],
        kpis: [],
      },
      {
        id: 'providers',
        title: 'Provider performance & trends',
        series: labels.map((label) => ({
          label,
          values: { yapily: span(96, 99), latencyMs: span(90, 160) },
        })),
        kpis: [],
      },
      {
        id: 'security',
        title: 'Security & risk alerts',
        series: labels.map((label) => ({
          label,
          values: { high: span(0, 5), medium: span(1, 8), low: span(2, 10) },
        })),
        kpis: [
          { label: 'Alerts raised', value: `${span(20, 60)}`, trend: '▲ 3 high', direction: 'down' },
          { label: 'Auto-blocked', value: `${span(1, 8)}`, trend: 'prevented', direction: 'up' },
        ],
      },
      {
        id: 'growth',
        title: 'User growth & engagement',
        series: labels.map((label) => ({
          label,
          values: { signups: span(30, 90), active: span(1500, 3500) },
        })),
        kpis: [
          { label: 'KYC conversion', value: `${span(78, 86)}%`, trend: '▲ 3%', direction: 'up' },
          { label: 'Retention (30d)', value: `${span(60, 70)}%`, trend: 'stable', direction: 'flat' },
        ],
      },
      {
        id: 'settlement',
        title: 'Settlement & float',
        series: labels.map((label) => ({
          label,
          values: { settled: span(30000, 50000), awaiting: span(1000, 4000) },
        })),
        kpis: [],
      },
      {
        id: 'revenue',
        title: 'Revenue & fees',
        series: labels.map((label) => ({ label, values: { feeRevenue: span(120, 260) } })),
        kpis: [
          { label: 'Fee revenue', value: `€${span(1200, 6000).toLocaleString()}`, trend: '▲ 6%', direction: 'up' },
          { label: 'Float yield', value: `€${span(20, 60)}`, trend: 'Aave/Morpho', direction: 'up' },
        ],
      },
    ];

    return { granularity: granularity as ReportGranularity, sections, preview: true };
  }
}
