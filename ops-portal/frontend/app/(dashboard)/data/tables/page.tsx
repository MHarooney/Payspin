'use client';

import { TableSummaryList } from '@payspin/shared-types';
import { useQuery } from '@tanstack/react-query';
import Link from 'next/link';
import { OpsLoadingPanel } from '@/components/ops/emblem-loader';
import { OpsCard, OpsPill, OpsSectionHead } from '@/components/ops/primitives';
import { apiRequest } from '@/lib/admin-api';

function fmt(n: number): string {
  if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)}M`;
  if (n >= 1_000) return `${(n / 1_000).toFixed(1)}k`;
  return String(n);
}

export default function TablesPage() {
  const { data, isLoading } = useQuery({
    queryKey: ['data-tables'],
    queryFn: () => apiRequest<TableSummaryList>('/data/tables'),
  });

  if (isLoading || !data) {
    return (
      <div className="content">
        <OpsLoadingPanel label="Loading tables…" size={36} />
      </div>
    );
  }

  const consumer = data.tables.filter((t) => t.group === 'consumer');
  const ops = data.tables.filter((t) => t.group === 'ops');

  const renderGroup = (label: string, tables: typeof data.tables) => (
    <>
      <div className="schema-section-label" style={{ marginBottom: 12 }}>
        {label}
      </div>
      <div className="tables-grid">
        {tables.map((t) => (
          <Link key={t.tableKey} href={`/data/tables/${t.tableKey}`} className="table-card">
            <div className="table-card-name">{t.modelName}</div>
            <div className="table-card-key mono">{t.dbTable}</div>
            <div className="table-card-footer">
              <span className="table-card-count">{fmt(t.rowCount)} rows</span>
              <OpsPill tone={t.group === 'consumer' ? 'ok' : 'blue'}>{t.group}</OpsPill>
            </div>
          </Link>
        ))}
      </div>
    </>
  );

  return (
    <div className="content">
      <OpsSectionHead
        title="Table Explorer"
        sub="Read-only preview of allowlisted tables. Sensitive fields are always redacted."
      />

      <div
        className="pill-banner"
        style={{ marginBottom: 20 }}
      >
        🔒 Sensitive fields (IBAN, password hashes, tokens, keys) are automatically
        redacted. This view is read-only. All row access is logged to the Audit Log.
      </div>

      <OpsCard title={undefined} count={undefined}>
        {renderGroup('Consumer tables', consumer)}
        <div style={{ height: 24 }} />
        {renderGroup('Ops tables', ops)}
        <div className="hint" style={{ marginTop: 12, fontSize: 11 }}>
          Cached at {new Date(data.cachedAt).toLocaleTimeString()}
        </div>
      </OpsCard>
    </div>
  );
}
