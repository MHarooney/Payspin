// Admin / Ops Portal DTOs. Consumed by ops-portal/backend (response shapes) and
// ops-portal/frontend (typed API client). Framework-agnostic.

export const ADMIN_API_BASE_PATH = '/admin/v1';

export enum AdminRole {
  SUPER_ADMIN = 'SUPER_ADMIN',
  OPS = 'OPS',
  SUPPORT = 'SUPPORT',
  READ_ONLY = 'READ_ONLY',
}

/** Online = lastSeenAt within 5 min. Recent = within 7 days. Never = no login. */
export type AdminUserPresence = 'online' | 'recent' | 'offline' | 'never';

export interface AdminProfile {
  id: string;
  email: string;
  displayName: string | null;
  role: AdminRole;
  lastLoginAt: string | null;
}

export interface AdminLoginResponse {
  accessToken: string;
  expiresIn: string;
  admin: AdminProfile;
}

export interface Paginated<T> {
  items: T[];
  total: number;
  page: number;
  pageSize: number;
  totalPages: number;
}

export type DashboardPeriod = 'today' | 'week' | 'month';

export interface DashboardKpi {
  label: string;
  value: string;
  trend: string | null;
  direction: 'up' | 'down' | 'flat';
}

export interface DashboardKpis {
  period: DashboardPeriod;
  kpis: DashboardKpi[];
}

export interface VolumePoint {
  label: string;
  volumeCents: number;
  count: number;
}

export interface VolumeSeries {
  period: DashboardPeriod;
  points: VolumePoint[];
}

export interface OpenAlert {
  id: string;
  title: string;
  detail: string;
  severity: 'HIGH' | 'MEDIUM' | 'LOW';
  status: string;
}

export type AdminPaymentStatus =
  | 'AWAITING_AUTHORIZATION'
  | 'PENDING'
  | 'PROCESSING'
  | 'COMPLETED'
  | 'FAILED'
  | 'CANCELLED';

export interface AdminPaymentListItem {
  id: string;
  shortCode: string;
  payeeName: string;
  payerBankName: string | null;
  amountCents: number;
  currency: string;
  status: AdminPaymentStatus;
  yapilyPaymentId: string | null;
  initiatedAt: string;
  completedAt: string | null;
}

export interface AdminPaymentDetail extends AdminPaymentListItem {
  paymentLinkId: string;
  description: string | null;
  idempotencyKey: string | null;
  yapilyAuthRequestId: string | null;
  webhookSnapshot: Record<string, unknown> | null;
  relatedWebhooks: AdminWebhookListItem[];
}

export interface AdminUserListItem {
  id: string;
  email: string;
  displayName: string | null;
  phoneE164: string | null;
  phoneVerified: boolean;
  bankVerified: boolean;
  kycStatus: string;
  kycTier: string | null;
  riskLevel: string;
  status: string;
  lifetimeVolumeCents: number;
  createdAt: string;
  lastLoginAt: string | null;
  lastSeenAt: string | null;
  presence: AdminUserPresence;
  registeredDeviceCount: number;
  isDeleted: boolean;
}

export interface AdminCircleListItem {
  id: string;
  name: string;
  status: string;
  memberCount: number;
  activeMemberCount: number;
  contributionCents: number;
  potCents: number;
  cycleDurationDays: number;
  currentRound: number;
  escrowCents: number;
  smartContractAddress: string | null;
  startedAt: string | null;
  createdAt: string;
}

export interface AdminCircleMember {
  id: string;
  userId: string;
  displayName: string | null;
  payoutOrder: number;
  status: string;
  isCurrentRecipient: boolean;
}

export interface AdminCircleDetail extends AdminCircleListItem {
  hostUserId: string;
  hostName: string | null;
  members: AdminCircleMember[];
}

export interface ServiceHealth {
  name: string;
  status: 'ok' | 'degraded' | 'down';
  stat: string;
  sub: string;
}

export interface SystemHealth {
  overall: 'ok' | 'degraded' | 'down';
  services: ServiceHealth[];
  checkedAt: string;
}

export interface FeatureFlagDto {
  key: string;
  label: string;
  description: string | null;
  enabled: boolean;
  category: string;
  updatedByEmail: string | null;
  updatedAt: string;
}

export interface PlatformConfigDto {
  key: string;
  label: string;
  value: string;
  valueType: string;
  group: string;
  description: string | null;
  updatedByEmail: string | null;
  updatedAt: string;
}

export interface KillSwitchState {
  active: boolean;
  updatedByEmail: string | null;
  updatedAt: string | null;
}

export interface AuditEventDto {
  id: string;
  adminEmail: string;
  action: string;
  targetType: string | null;
  targetId: string | null;
  before: unknown;
  after: unknown;
  ip: string | null;
  createdAt: string;
}

export interface GlobalSearchResult {
  type: 'payment' | 'user' | 'payment_link';
  id: string;
  label: string;
  sub: string;
}

// ---- Phase 2 DTOs ----

export interface ComplianceAlertDto {
  id: string;
  type: string;
  subject: string;
  subjectRef: string | null;
  rule: string;
  severity: string;
  status: string;
  createdAt: string;
}

export interface DisputeDto {
  id: string;
  caseRef: string;
  type: string;
  amountCents: number;
  currency: string;
  parties: string;
  status: string;
  createdAt: string;
}

export interface ReconciliationException {
  id: string;
  txId: string;
  ledger: string;
  bank: string;
  deltaCents: number;
  status: string;
}

export interface SupportMessageDto {
  id: string;
  direction: 'IN' | 'OUT';
  body: string;
  authorName: string;
  createdAt: string;
}

export interface SupportThreadDto {
  id: string;
  userRef: string;
  subjectName: string;
  meta: string | null;
  status: string;
  unread: boolean;
  preview: string;
  lastMessageAt: string;
}

export interface SupportThreadDetail extends SupportThreadDto {
  messages: SupportMessageDto[];
}

export type ReportGranularity = 'hourly' | 'daily' | 'weekly' | 'monthly';

export interface ReportSeriesPoint {
  label: string;
  values: Record<string, number>;
}

export interface ReportSection {
  id: string;
  title: string;
  series: ReportSeriesPoint[];
  kpis: DashboardKpi[];
}

export interface ReportsResponse {
  granularity: ReportGranularity;
  sections: ReportSection[];
  preview: boolean;
}

export interface AppControlModule {
  key: string;
  label: string;
  description: string;
  enabled: boolean;
}

export interface AppControlsResponse {
  modules: AppControlModule[];
  banner: { text: string; tone: string } | null;
  defaults: PlatformConfigDto[];
  preview: boolean;
}

// ---- Data Explorer DTOs ----

export interface SchemaFieldDto {
  name: string;
  type: string;
  isRequired: boolean;
  isList: boolean;
  isRelation: boolean;
  relationName?: string;
  relationTarget?: string;
}

export interface SchemaRelationDto {
  name: string;
  from: string;
  to: string;
  kind: 'one-to-one' | 'one-to-many' | 'many-to-one' | 'many-to-many';
}

export interface SchemaModelDto {
  name: string;
  dbTable: string;
  fields: SchemaFieldDto[];
}

export interface SchemaMetadata {
  models: SchemaModelDto[];
  relations: SchemaRelationDto[];
}

export interface TableSummary {
  tableKey: string;
  modelName: string;
  dbTable: string;
  rowCount: number;
  group: 'consumer' | 'ops';
}

export interface TableSummaryList {
  tables: TableSummary[];
  cachedAt: string;
}

export interface TableRowsPreview {
  tableKey: string;
  columns: string[];
  rows: Record<string, unknown>[];
  total: number;
  page: number;
  pageSize: number;
  totalPages: number;
}

// ---- User 360° DTOs ----

export interface AdminUserBankAccount {
  id: string;
  ibanLast4: string;
  bankName: string | null;
  accountHolder: string;
  verified: boolean;
  isPrimary: boolean;
}

export interface AdminUserStateDto {
  status: string;
  kycTier: string | null;
  kycStatus: string;
  riskLevel: string;
  note: string | null;
  frozenReason: string | null;
  updatedByEmail: string | null;
  updatedAt: string;
}

export interface AdminUserCircleSummary {
  id: string;
  name: string;
  status: string;
  role: 'host' | 'member';
  payoutOrder: number | null;
}

export interface AdminUserDetail extends AdminUserListItem {
  paymentCount: number;
  paymentLinkCount: number;
  bankAccounts: AdminUserBankAccount[];
  recentPayments: AdminPaymentListItem[];
  recentPaymentLinks: AdminPaymentLinkListItem[];
  circles: AdminUserCircleSummary[];
  adminState: AdminUserStateDto | null;
  auditEvents: AuditEventDto[];
  devices: AdminUserDevice[];
}

export interface AdminUserDevice {
  id: string;
  platform: string;
  lastUpdatedAt: string;
}

// ---- Webhooks ----
export interface AdminWebhookListItem {
  id: string;
  eventId: string;
  eventType: string;
  processedAt: string | null;
  linkedPaymentId: string | null;
  createdAt: string;
}

export interface AdminWebhookDetail extends AdminWebhookListItem {
  payloadSummary: Record<string, unknown>;
}

// ---- Payment Links (ops) ----
export interface AdminPaymentLinkListItem {
  id: string;
  shortCode: string;
  payeeName: string;
  payeeUserId: string;
  amountCents: number | null;
  currency: string;
  description: string | null;
  status: string;
  linkType: string;
  useCount: number;
  maxUses: number | null;
  expiresAt: string | null;
  createdAt: string;
}

export interface AdminPaymentLinkDetail extends AdminPaymentLinkListItem {
  payments: AdminPaymentListItem[];
}

// ---- Admin Staff (ops staff CRUD) ----
export interface AdminStaffListItem {
  id: string;
  email: string;
  displayName: string | null;
  role: AdminRole;
  isActive: boolean;
  lastLoginAt: string | null;
  createdAt: string;
}

// ---- Write payloads (returned from mutations) ----
export interface CreateUserAdminResult {
  id: string;
  email: string;
  displayName: string | null;
  tempPassword: string;
}

