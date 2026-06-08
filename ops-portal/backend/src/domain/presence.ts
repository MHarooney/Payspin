import type { AdminUserPresence } from '@payspin/shared-types';

const ONLINE_MS = 5 * 60 * 1000;      // 5 minutes
const RECENT_MS = 7 * 24 * 60 * 60 * 1000; // 7 days

export function computePresence(lastLoginAt: Date | null, lastSeenAt: Date | null): AdminUserPresence {
  const seenAt = lastSeenAt ?? lastLoginAt;
  if (!seenAt) return 'never';
  const age = Date.now() - seenAt.getTime();
  if (age <= ONLINE_MS) return 'online';
  if (age <= RECENT_MS) return 'recent';
  return 'offline';
}
