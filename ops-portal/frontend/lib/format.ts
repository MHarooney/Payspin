export function eur(cents: number): string {
  const value = cents / 100;
  if (Math.abs(value) >= 1_000_000) return `€${(value / 1_000_000).toFixed(2)}M`;
  if (Math.abs(value) >= 10_000) return `€${Math.round(value / 1000)}k`;
  return `€${value.toLocaleString('en-IE', { minimumFractionDigits: value % 1 === 0 ? 0 : 2, maximumFractionDigits: 2 })}`;
}

export function eurExact(cents: number): string {
  return new Intl.NumberFormat('en-IE', { style: 'currency', currency: 'EUR' }).format(cents / 100);
}

export function relativeTime(iso: string): string {
  const diff = Date.now() - new Date(iso).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return 'just now';
  if (mins < 60) return `${mins} min ago`;
  const hours = Math.floor(mins / 60);
  if (hours < 24) return `${hours}h ago`;
  const days = Math.floor(hours / 24);
  return `${days}d ago`;
}

export function clock(iso: string): string {
  return new Date(iso).toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit', second: '2-digit' });
}

const STATUS_PILL: Record<string, string> = {
  COMPLETED: 'ok',
  SETTLED: 'ok',
  ACTIVE: 'ok',
  VERIFIED: 'ok',
  PENDING: 'pend',
  PROCESSING: 'pend',
  ONBOARDING: 'pend',
  FORMING: 'pend',
  DRAFT: 'pend',
  AWAITING_AUTHORIZATION: 'blue',
  FAILED: 'fail',
  CANCELLED: 'fail',
  FROZEN: 'fail',
  SUSPENDED: 'fail',
  BLOCKED: 'fail',
  COMPLETED_CIRCLE: 'blue',
};

export function statusPill(status: string): string {
  return STATUS_PILL[status] ?? 'blue';
}
