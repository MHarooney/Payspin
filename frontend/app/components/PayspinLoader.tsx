/* eslint-disable @next/next/no-img-element */

/**
 * Branded loader — split arc + loop layers spinning together (2.4s).
 * Theme-aware: white on dark, gradient on light.
 */
export default function PayspinLoader({
  size = 56,
  label,
}: {
  size?: number;
  label?: string;
}) {
  return (
    <div
      className="ps-loader"
      style={{ width: size, height: size }}
      role="status"
      aria-live="polite"
      aria-label={label ?? 'Loading'}
    >
      <div className="ps-loader__layers">
        <img
          className="ps-loader__arc ps-loader__arc--white"
          src="/payspin-emblem-arc-white.png"
          alt=""
          aria-hidden="true"
        />
        <img
          className="ps-loader__loop ps-loader__loop--white"
          src="/payspin-emblem-loop-white.png"
          alt=""
          aria-hidden="true"
        />
        <img
          className="ps-loader__arc ps-loader__arc--gradient"
          src="/payspin-emblem-arc-gradient.png"
          alt=""
          aria-hidden="true"
        />
        <img
          className="ps-loader__loop ps-loader__loop--gradient"
          src="/payspin-emblem-loop-gradient.png"
          alt=""
          aria-hidden="true"
        />
      </div>
    </div>
  );
}
