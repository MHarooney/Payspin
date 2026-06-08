'use client';

import { TableRowsPreview } from '@payspin/shared-types';
import { useQuery } from '@tanstack/react-query';
import Link from 'next/link';
import { use, useState } from 'react';
import { OpsLoadingPanel } from '@/components/ops/emblem-loader';
import { OpsCard, OpsSectionHead } from '@/components/ops/primitives';
import { apiRequest } from '@/lib/admin-api';

function CopyableCell({ value }: { value: unknown }) {
  const str = value === null || value === undefined ? '—' : String(value);
  const isRedacted = str === '***REDACTED***';
  const isId = str.length === 36 && str.split('-').length === 5;

  const copy = () => {
    if (!isRedacted) navigator.clipboard.writeText(str).catch(() => {});
  };

  return (
    <td
      onClick={copy}
      title={isRedacted ? 'Redacted' : isId ? 'Click to copy' : undefined}
      className={`table-cell${isRedacted ? ' redacted' : ''}${isId ? ' copyable' : ''}`}
    >
      <span className={isId ? 'mono' : undefined}>{str.length > 60 ? `${str.slice(0, 60)}…` : str}</span>
    </td>
  );
}

export default function TableRowsPage({ params }: { params: Promise<{ tableKey: string }> }) {
  const { tableKey } = use(params);
  const [page, setPage] = useState(1);

  const { data, isLoading, isError } = useQuery({
    queryKey: ['table-rows', tableKey, page],
    queryFn: () =>
      apiRequest<TableRowsPreview>(`/data/tables/${tableKey}/rows`, {
        query: { page, pageSize: 20 },
      }),
  });

  return (
    <div className="content">
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 4 }}>
        <Link href="/data/tables" className="back-link">
          ← Tables
        </Link>
      </div>

      <OpsSectionHead title={tableKey.replace(/_/g, ' ')} sub={`/data/tables/${tableKey}`} />

      <div className="pill-banner" style={{ marginBottom: 16 }}>
        🔒 Sensitive fields are redacted. Read-only preview. All access is logged.
      </div>

      {isLoading && <OpsLoadingPanel label="Loading rows…" size={32} />}

      {isError && (
        <OpsCard title={undefined} count={undefined}>
          <div className="hint" style={{ padding: 24 }}>
            Could not load rows — you may not have permission, or the table is unavailable.
          </div>
        </OpsCard>
      )}

      {data && (
        <OpsCard title={undefined} count={undefined} className="table-browser-card">
          <div className="table-browser-meta">
            <span>
              {data.total.toLocaleString()} rows · page {data.page}/{data.totalPages}
            </span>
          </div>

          <div className="table-browser-scroll">
            <table className="table-browser">
              <thead>
                <tr>
                  {data.columns.map((col) => (
                    <th key={col}>{col}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {data.rows.map((row, i) => (
                  <tr key={i}>
                    {data.columns.map((col) => (
                      <CopyableCell key={col} value={row[col]} />
                    ))}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {data.totalPages > 1 && (
            <div className="table-browser-pagination">
              <button
                className="mini-btn"
                disabled={page <= 1}
                onClick={() => setPage((p) => p - 1)}
              >
                ← Prev
              </button>
              <span className="hint">
                {page} / {data.totalPages}
              </span>
              <button
                className="mini-btn"
                disabled={page >= data.totalPages}
                onClick={() => setPage((p) => p + 1)}
              >
                Next →
              </button>
            </div>
          )}
        </OpsCard>
      )}
    </div>
  );
}
