import { DashboardPeriod } from '@payspin/shared-types';

export interface Range {
  start: Date;
  end: Date;
}

/** Current and previous comparison windows for a dashboard period. */
export function periodRanges(period: DashboardPeriod, now = new Date()): {
  current: Range;
  previous: Range;
} {
  const end = now;
  const start = new Date(now);
  if (period === 'today') {
    start.setHours(0, 0, 0, 0);
  } else if (period === 'week') {
    start.setDate(start.getDate() - 7);
  } else {
    start.setMonth(start.getMonth() - 1);
  }
  const span = end.getTime() - start.getTime();
  return {
    current: { start, end },
    previous: { start: new Date(start.getTime() - span), end: start },
  };
}

/** Bucket labels + boundaries for the dashboard volume chart. */
export function volumeBuckets(period: DashboardPeriod, now = new Date()): {
  label: string;
  start: Date;
  end: Date;
}[] {
  const buckets: { label: string; start: Date; end: Date }[] = [];
  if (period === 'today') {
    const base = new Date(now);
    base.setHours(0, 0, 0, 0);
    for (let h = 0; h < 24; h++) {
      const start = new Date(base);
      start.setHours(h);
      const end = new Date(start);
      end.setHours(h + 1);
      buckets.push({ label: `${h}:00`, start, end });
    }
  } else if (period === 'week') {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    for (let d = 6; d >= 0; d--) {
      const start = new Date(now);
      start.setHours(0, 0, 0, 0);
      start.setDate(start.getDate() - d);
      const end = new Date(start);
      end.setDate(end.getDate() + 1);
      buckets.push({ label: days[start.getDay()], start, end });
    }
  } else {
    for (let d = 29; d >= 0; d--) {
      const start = new Date(now);
      start.setHours(0, 0, 0, 0);
      start.setDate(start.getDate() - d);
      const end = new Date(start);
      end.setDate(end.getDate() + 1);
      buckets.push({ label: `${start.getDate()}/${start.getMonth() + 1}`, start, end });
    }
  }
  return buckets;
}
