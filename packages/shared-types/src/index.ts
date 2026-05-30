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
