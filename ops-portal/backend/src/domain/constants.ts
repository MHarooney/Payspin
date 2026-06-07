/** Feature-flag key that backs the platform-wide kill switch. */
export const KILL_SWITCH_FLAG_KEY = 'platform_kill_switch';

/** Audit action identifiers (kept in sync with the mockup's audit log). */
export const AuditAction = {
  ADMIN_LOGIN: 'ADMIN_LOGIN',
  TX_RETRY: 'TX_RETRY',
  USER_STATE_UPDATE: 'USER_STATE_UPDATE',
  KYC_APPROVE: 'KYC_APPROVE',
  USER_FREEZE: 'USER_FREEZE',
  CONFIG_UPDATE: 'CONFIG_UPDATE',
  FLAG_TOGGLE: 'FLAG_TOGGLE',
  KILL_SWITCH_ON: 'KILL_SWITCH_ON',
  KILL_SWITCH_OFF: 'KILL_SWITCH_OFF',
} as const;

export type AuditActionType = (typeof AuditAction)[keyof typeof AuditAction];
