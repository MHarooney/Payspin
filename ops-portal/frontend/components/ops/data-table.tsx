'use client';

import { ReactNode } from 'react';
import { OpsEmptyState } from './primitives';

export interface Column<T> {
  header: string;
  cell: (row: T) => ReactNode;
}

export function OpsDataTable<T>({
  columns,
  rows,
  empty = 'Nothing to show yet.',
  rowKey,
}: {
  columns: Column<T>[];
  rows: T[];
  empty?: string;
  rowKey: (row: T, index: number) => string;
}) {
  if (rows.length === 0) {
    return <OpsEmptyState message={empty} />;
  }
  return (
    <table>
      <thead>
        <tr>
          {columns.map((c) => (
            <th key={c.header}>{c.header}</th>
          ))}
        </tr>
      </thead>
      <tbody>
        {rows.map((row, i) => (
          <tr key={rowKey(row, i)}>
            {columns.map((c) => (
              <td key={c.header}>{c.cell(row)}</td>
            ))}
          </tr>
        ))}
      </tbody>
    </table>
  );
}
