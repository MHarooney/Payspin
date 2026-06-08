/* eslint-disable @next/next/no-img-element */

/** Theme-aware Payspin emblem — white on dark, gradient on light (payer web parity). */
export function OpsPayspinEmblem({
  size = 28,
  className = '',
}: {
  size?: number;
  className?: string;
}) {
  return (
    <span
      className={`ops-emblem ${className}`.trim()}
      style={{ width: size, height: size }}
      aria-hidden="true"
    >
      <img className="ops-emblem__white" src="/payspin-emblem-white.png" alt="" />
      <img className="ops-emblem__gradient" src="/payspin-emblem-gradient.png" alt="" />
    </span>
  );
}
