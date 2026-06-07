'use client';

import { useId } from 'react';
import {
  PAYSPIN_EMBLEM_ARC_FILL,
  PAYSPIN_EMBLEM_ARC_SPINE,
  PAYSPIN_EMBLEM_LOOP_FILL,
  PAYSPIN_EMBLEM_LOOP_SPINE,
  PAYSPIN_EMBLEM_VIEWBOX,
} from '@/lib/emblem-paths';

/** Branded loading indicator — loops the splash emblem assemble + breathing pulse (Flutter parity). */
export function OpsEmblemLoader({
  size = 48,
  label = 'Loading',
  glow,
}: {
  size?: number;
  label?: string;
  glow?: boolean;
}) {
  const uid = useId().replace(/:/g, '');
  const gradId = `ops-emblem-grad-${uid}`;
  const arcMaskId = `ops-emblem-arc-mask-${uid}`;
  const loopMaskId = `ops-emblem-loop-mask-${uid}`;
  const showGlow = glow ?? size >= 40;

  return (
    <div
      className={`ops-emblem-loader${showGlow ? ' ops-emblem-loader--glow' : ''}`}
      style={{ width: size, height: size }}
      role="status"
      aria-live="polite"
      aria-label={label}
    >
      <svg
        className="ops-emblem-loader__svg"
        viewBox={PAYSPIN_EMBLEM_VIEWBOX}
        width={size}
        height={size}
        aria-hidden="true"
      >
        <defs>
          <linearGradient id={gradId} x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#FC00FF" />
            <stop offset="100%" stopColor="#07D8DD" />
          </linearGradient>
          <mask id={arcMaskId}>
            <rect width="100" height="100" fill="black" />
            <path
              className="ops-emblem-loader__stroke ops-emblem-loader__stroke--arc"
              d={PAYSPIN_EMBLEM_ARC_SPINE}
              pathLength={1}
              strokeDasharray="1"
              strokeDashoffset="1"
              fill="none"
              stroke="white"
              strokeWidth={16}
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          </mask>
          <mask id={loopMaskId}>
            <rect width="100" height="100" fill="black" />
            <path
              className="ops-emblem-loader__stroke ops-emblem-loader__stroke--loop"
              d={PAYSPIN_EMBLEM_LOOP_SPINE}
              pathLength={1}
              strokeDasharray="1"
              strokeDashoffset="1"
              fill="none"
              stroke="white"
              strokeWidth={16}
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          </mask>
        </defs>
        <g className="ops-emblem-loader__art ops-emblem-loader__art--white">
          <path d={PAYSPIN_EMBLEM_LOOP_FILL} fill="#ffffff" mask={`url(#${loopMaskId})`} />
          <path d={PAYSPIN_EMBLEM_ARC_FILL} fill="#ffffff" mask={`url(#${arcMaskId})`} />
        </g>
        <g className="ops-emblem-loader__art ops-emblem-loader__art--gradient">
          <path d={PAYSPIN_EMBLEM_LOOP_FILL} fill={`url(#${gradId})`} mask={`url(#${loopMaskId})`} />
          <path d={PAYSPIN_EMBLEM_ARC_FILL} fill={`url(#${gradId})`} mask={`url(#${arcMaskId})`} />
        </g>
      </svg>
    </div>
  );
}

/** Full-screen or section loading placeholder — mirrors Flutter `PayspinPageLoader`. */
export function OpsPageLoader({
  size = 56,
  label = 'Loading',
}: {
  size?: number;
  label?: string;
}) {
  return (
    <div className="ops-page-loader">
      <OpsEmblemLoader size={size} label={label} glow />
    </div>
  );
}

/** Centered loader for tables, drawers, and panels. */
export function OpsLoadingPanel({
  label = 'Loading',
  size = 40,
}: {
  label?: string;
  size?: number;
}) {
  return (
    <div className="ops-loading-panel">
      <OpsEmblemLoader size={size} label={label} glow />
    </div>
  );
}
