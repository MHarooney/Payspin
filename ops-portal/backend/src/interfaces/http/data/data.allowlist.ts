/**
 * Single source of truth for the data explorer allowlist.
 * Never accept arbitrary table names from user input.
 */

export const DATA_EXPLORER_ALLOWLIST = [
  'users',
  'payments',
  'payment_links',
  'bank_accounts',
  'circles',
  'circle_members',
  'feature_flags',
  'platform_config',
  'user_admin_states',
  'compliance_alerts',
  'disputes',
  'support_threads',
] as const;

export type AllowedTableKey = (typeof DATA_EXPLORER_ALLOWLIST)[number];

// admin_users and admin_audit_events excluded — they have dedicated pages.
// webhook_events excluded — payload contains raw Yapily PII.
// bank_connections excluded — yapilyAuthId requires special gating.

/** Map from URL tableKey → Prisma delegate accessor name. */
export const TABLE_KEY_TO_MODEL: Record<string, string> = {
  users: 'user',
  payments: 'payment',
  payment_links: 'paymentLink',
  bank_accounts: 'bankAccount',
  circles: 'circle',
  circle_members: 'circleMember',
  feature_flags: 'featureFlag',
  platform_config: 'platformConfig',
  user_admin_states: 'userAdminState',
  compliance_alerts: 'complianceAlert',
  disputes: 'dispute',
  support_threads: 'supportThread',
};

/** Human-readable display name per table key. */
export const TABLE_DISPLAY_NAME: Record<string, string> = {
  users: 'Users',
  payments: 'Payments',
  payment_links: 'Payment Links',
  bank_accounts: 'Bank Accounts',
  circles: 'Circles',
  circle_members: 'Circle Members',
  feature_flags: 'Feature Flags',
  platform_config: 'Platform Config',
  user_admin_states: 'User Admin States',
  compliance_alerts: 'Compliance Alerts',
  disputes: 'Disputes',
  support_threads: 'Support Threads',
};

/** Tables belonging to the consumer product (vs ops-portal). */
export const CONSUMER_TABLES = new Set([
  'users',
  'payments',
  'payment_links',
  'bank_accounts',
  'circles',
  'circle_members',
]);

/**
 * Fields that must always be redacted — never exposed in row preview.
 * Listed in both camelCase (Prisma) and snake_case (raw DB).
 */
export const REDACTED_FIELDS = new Set([
  'passwordHash',
  'password_hash',
  'ibanEncrypted',
  'iban_encrypted',
  'ibanIv',
  'iban_iv',
  'yapilyConsentToken',
  'yapily_consent_token',
  'paymentRequestSnapshot',
  'payment_request_snapshot',
  'webhookRaw',
  'webhook_raw',
  'inviteCode',
  'invite_code',
  'moneriumIban',
  'monerium_iban',
  'yapilyAuthId',
  'yapily_auth_id',
  'before',
  'after',
]);

export function redactRow(row: Record<string, unknown>): Record<string, unknown> {
  const result: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(row)) {
    if (REDACTED_FIELDS.has(key)) {
      result[key] = '***REDACTED***';
    } else {
      result[key] = value;
    }
  }
  return result;
}
