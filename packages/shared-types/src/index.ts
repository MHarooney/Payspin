export * from './admin';
export * from './support';

export enum PaymentLinkStatus {
  ACTIVE = 'ACTIVE',
  EXPIRED = 'EXPIRED',
  CANCELLED = 'CANCELLED',
  SETTLED = 'SETTLED',
  COLLECTING = 'COLLECTING',
}

export enum PaymentLinkType {
  SINGLE = 'SINGLE',
  MULTI = 'MULTI',
}

export enum PaymentStatus {
  AWAITING_AUTHORIZATION = 'AWAITING_AUTHORIZATION',
  PENDING = 'PENDING',
  PROCESSING = 'PROCESSING',
  COMPLETED = 'COMPLETED',
  FAILED = 'FAILED',
  CANCELLED = 'CANCELLED',
}

export interface UserProfile {
  id: string;
  email: string;
  displayName: string | null;
  phoneE164: string | null;
  phoneVerified: boolean;
  createdAt: string;
}

export interface AuthResponse {
  accessToken: string;
  user: UserProfile;
}

export interface BankAccountSummary {
  id: string;
  ibanLast4: string;
  accountHolder: string;
  bankName: string | null;
  verified: boolean;
  /** Exactly one account per user is primary; it is the default for new links. */
  isPrimary: boolean;
  createdAt: string;
}

export interface PaymentLinkSummary {
  id: string;
  shortCode: string;
  amountCents: number | null;
  currency: string;
  description: string | null;
  status: PaymentLinkStatus;
  linkType: PaymentLinkType;
  useCount: number;
  maxUses: number | null;
  expiresAt: string | null;
  createdAt: string;
  payUrl: string;
  completedPaymentCount: number;
  totalReceivedCents: number;
}

export interface PaymentSummary {
  id: string;
  amountCents: number;
  currency: string;
  status: PaymentStatus;
  payerBankName: string | null;
  initiatedAt: string;
  completedAt: string | null;
}

export interface PaymentLinkDetail extends PaymentLinkSummary {
  payments: PaymentSummary[];
}

export interface PublicPaymentLinkView {
  shortCode: string;
  amountCents: number | null;
  currency: string;
  description: string | null;
  payeeDisplayName: string;
  status: PaymentLinkStatus;
  expiresAt: string | null;
}

export interface InitiatePaymentResponse {
  paymentId: string;
  redirectUrl: string;
}

export interface PaymentPublicStatus {
  status: PaymentStatus;
  amountCents: number;
  currency: string;
  completedAt: string | null;
}

export const API_BASE_PATH = '/v1';

export enum NotificationType {
  PAYMENT_RECEIVED = 'payment.received',
  PAYMENT_FAILED = 'payment.failed',
  LINK_EXPIRED = 'link.expired',
  SUPPORT_REPLY = 'support.reply',
}

export interface NotificationSummary {
  id: string;
  type: string;
  title: string;
  body: string;
  data: Record<string, unknown> | null;
  readAt: string | null;
  createdAt: string;
}

export interface NotificationListResponse {
  items: NotificationSummary[];
  unreadCount: number;
  nextCursor: string | null;
}

export interface RegisterDeviceTokenResponse {
  registered: boolean;
}

export interface VerifyPhoneResponse {
  phoneVerified: boolean;
  phoneVerifiedAt: string | null;
}

export enum CircleStatus {
  DRAFT = 'DRAFT',
  ACTIVE = 'ACTIVE',
  COMPLETED = 'COMPLETED',
  CANCELLED = 'CANCELLED',
}

export enum CircleMemberStatus {
  ACTIVE = 'ACTIVE',
  REMOVED = 'REMOVED',
}

export interface CircleMemberView {
  id: string;
  userId: string;
  displayName: string | null;
  payoutOrder: number;
  status: CircleMemberStatus;
  isCurrentRecipient: boolean;
}

export interface CircleSummary {
  id: string;
  name: string;
  status: CircleStatus;
  memberCount: number;
  activeMemberCount: number;
  contributionCents: number;
  cycleDurationDays: number;
  currentRound: number;
  hostUserId: string;
  isHost: boolean;
  inviteCode: string | null;
  startedAt: string | null;
  createdAt: string;
}

export interface CircleDetail extends CircleSummary {
  members: CircleMemberView[];
  currentRecipientDisplayName: string | null;
}
