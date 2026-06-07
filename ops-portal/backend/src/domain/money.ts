/** Format integer cents as a compact EUR string for dense ops KPI cards. */
export function eur(cents: number): string {
  const value = cents / 100;
  if (Math.abs(value) >= 1_000_000) {
    return `€${(value / 1_000_000).toFixed(2)}M`;
  }
  if (Math.abs(value) >= 10_000) {
    return `€${Math.round(value / 1000)}k`;
  }
  return `€${value.toLocaleString('en-IE', { maximumFractionDigits: 0 })}`;
}

export function trendPct(current: number, previous: number): {
  trend: string;
  direction: 'up' | 'down' | 'flat';
} {
  if (previous === 0) {
    return current === 0
      ? { trend: 'stable', direction: 'flat' }
      : { trend: 'new', direction: 'up' };
  }
  const pct = ((current - previous) / previous) * 100;
  if (Math.abs(pct) < 0.05) {
    return { trend: 'stable', direction: 'flat' };
  }
  const direction = pct > 0 ? 'up' : 'down';
  const arrow = pct > 0 ? '▲' : '▼';
  return { trend: `${arrow} ${Math.abs(pct).toFixed(1)}%`, direction };
}
