/* eslint-disable @next/next/no-img-element */

/**
 * Theme-aware Payspin emblem. Renders both variants and lets CSS show the right
 * one for the active `data-theme` (white on dark, gradient on light) so it works
 * without JS and never flashes the wrong logo.
 */
export default function PayspinEmblem({
  size = 28,
  className = '',
}: {
  size?: number;
  className?: string;
}) {
  return (
    <span
      className={`ps-emblem ${className}`.trim()}
      style={{ width: size, height: size }}
      aria-hidden="true"
    >
      <img className="ps-emblem__white" src="/payspin-emblem-white.png" alt="" />
      <img className="ps-emblem__gradient" src="/payspin-emblem-gradient.png" alt="" />
    </span>
  );
}
