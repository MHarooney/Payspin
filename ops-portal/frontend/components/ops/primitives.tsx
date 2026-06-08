'use client';

import { DashboardKpi } from '@payspin/shared-types';
import { ReactNode } from 'react';

export function OpsCard({
  title,
  count,
  children,
  className,
}: {
  title?: ReactNode;
  count?: ReactNode;
  children: ReactNode;
  className?: string;
}) {
  return (
    <div className={`card${className ? ` ${className}` : ''}`}>
      {title && (
        <h3>
          {title}
          {count}
        </h3>
      )}
      {children}
    </div>
  );
}

export function OpsPill({ tone, children }: { tone: string; children: ReactNode }) {
  return <span className={`pill ${tone}`}>{children}</span>;
}

export function OpsPreviewBadge() {
  return <span className="preview-badge">Preview</span>;
}

export function OpsSegment<T extends string>({
  options,
  value,
  onChange,
}: {
  options: { value: T; label: string }[];
  value: T;
  onChange: (v: T) => void;
}) {
  return (
    <div className="seg">
      {options.map((o) => (
        <button
          key={o.value}
          className={o.value === value ? 'active' : ''}
          onClick={() => onChange(o.value)}
        >
          {o.label}
        </button>
      ))}
    </div>
  );
}

export function OpsKpiStrip({ kpis, columns }: { kpis: DashboardKpi[]; columns?: number }) {
  return (
    <div className="kpis" style={columns ? { gridTemplateColumns: `repeat(${columns}, 1fr)` } : undefined}>
      {kpis.map((k, i) => (
        <div className="kpi" key={`${k.label}-${i}`}>
          <div className="label">{k.label}</div>
          <div className="val">{k.value}</div>
          {k.trend && <div className={`trend ${k.direction}`}>{k.trend}</div>}
        </div>
      ))}
    </div>
  );
}

export function OpsSectionHead({
  title,
  sub,
  preview,
  children,
}: {
  title: string;
  sub?: string;
  preview?: boolean;
  children?: ReactNode;
}) {
  return (
    <div className="section-head">
      <div>
        <h3 style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          {title}
          {preview && <OpsPreviewBadge />}
        </h3>
        {sub && <div className="sub">{sub}</div>}
      </div>
      {children}
    </div>
  );
}

export function OpsEmptyState({ message }: { message: string }) {
  return <div className="empty">{message}</div>;
}

export function OpsTableSkeleton({ rows = 5, cols = 5 }: { rows?: number; cols?: number }) {
  return (
    <div className="card">
      {Array.from({ length: rows }).map((_, r) => (
        <div key={r} style={{ display: 'flex', gap: 12, padding: '12px 0' }}>
          {Array.from({ length: cols }).map((_, c) => (
            <div key={c} className="skeleton" style={{ height: 16, flex: 1 }} />
          ))}
        </div>
      ))}
    </div>
  );
}
