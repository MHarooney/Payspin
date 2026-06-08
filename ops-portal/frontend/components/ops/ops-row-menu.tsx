'use client';

import { ReactNode, useEffect, useRef, useState } from 'react';

export interface RowMenuItem {
  label: string;
  onClick: () => void;
  tone?: 'danger';
  disabled?: boolean;
}

export function OpsRowMenu({ items }: { items: RowMenuItem[] }) {
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!open) return;
    const close = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false);
    };
    document.addEventListener('mousedown', close);
    return () => document.removeEventListener('mousedown', close);
  }, [open]);

  return (
    <div className="row-menu-wrap" ref={ref} onClick={(e) => e.stopPropagation()}>
      <button
        type="button"
        className="row-menu-trigger"
        aria-label="Actions"
        onClick={() => setOpen((v) => !v)}
      >
        ⋯
      </button>
      {open && (
        <div className="row-menu-dropdown">
          {items.map((item) => (
            <button
              key={item.label}
              type="button"
              className={`row-menu-item${item.tone === 'danger' ? ' danger' : ''}`}
              disabled={item.disabled}
              onClick={() => {
                setOpen(false);
                item.onClick();
              }}
            >
              {item.label}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

export function OpsEmptyState({
  title,
  hint,
  action,
}: {
  title: string;
  hint?: string;
  action?: ReactNode;
}) {
  return (
    <div className="ops-empty-state">
      <div className="ops-empty-title">{title}</div>
      {hint && <p className="hint">{hint}</p>}
      {action}
    </div>
  );
}
