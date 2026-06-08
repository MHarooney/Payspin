import { OpsPayspinEmblem } from './payspin-emblem';

const EMBLEM_SIZE = {
  inline: 22,
  auth: 48,
  hero: 64,
} as const;

/** Sidebar / login brand lockup — emblem + Payspin wordmark + optional OPS label. */
export function OpsBrandMark({
  variant = 'inline',
  showOps = true,
  className = '',
}: {
  variant?: keyof typeof EMBLEM_SIZE;
  showOps?: boolean;
  className?: string;
}) {
  return (
    <div className={`ops-brand-mark ops-brand-mark--${variant} ${className}`.trim()}>
      <OpsPayspinEmblem size={EMBLEM_SIZE[variant]} />
      <span className="ops-brand-mark__text">
        <span className="ops-brand-mark__name">Payspin</span>
        {showOps && <span className="ops-brand-mark__ops">OPS</span>}
      </span>
    </div>
  );
}
