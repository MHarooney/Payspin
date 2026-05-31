import { PaymentStatus } from '@payspin/shared-types';

export interface PaymentRequestPayload {
  type: string;
  paymentIdempotencyId: string;
  reference: string;
  amount: { amount: number; currency: string };
  payee: {
    name: string;
    accountIdentifications: Array<{ type: string; identification: string }>;
  };
}

export interface PaymentAuthRequestParams {
  applicationUserId: string;
  institutionId?: string;
  callbackUrl: string;
  paymentRequest: PaymentRequestPayload;
}

export interface PaymentAuthRequestResult {
  authRequestId: string;
  authorisationUrl: string;
}

export interface CreatePaymentParams {
  consentToken: string;
  paymentRequest: PaymentRequestPayload;
  idempotencyKey: string;
}

export interface CreatePaymentResult {
  paymentId: string;
  status: PaymentStatus;
}

export interface InstitutionSummary {
  id: string;
  name: string;
  fullName: string;
  countries: Array<{ countryCode2: string; displayName: string }>;
}

export interface AccountAuthRequestParams {
  applicationUserId: string;
  institutionId?: string;
  callbackUrl: string;
}

export interface AccountAuthRequestResult {
  connectionId: string;
  authorisationUrl: string;
}

export interface YapilyAccount {
  id: string;
  type: string;
  accountNames?: Array<{ name: string }>;
  accountIdentifications?: Array<{ type: string; identification: string }>;
  institution?: { name?: string };
}

export interface PisGateway {
  createPaymentAuthRequest(params: PaymentAuthRequestParams): Promise<PaymentAuthRequestResult>;
  createPayment(params: CreatePaymentParams): Promise<CreatePaymentResult>;
  getPaymentStatus(paymentId: string, consentToken?: string): Promise<PaymentStatus>;
  verifyWebhookSignature(rawBody: string, signature: string): boolean;
}

export interface AisGateway {
  listInstitutions(country: string): Promise<InstitutionSummary[]>;
  createAccountAuthRequest(params: AccountAuthRequestParams): Promise<AccountAuthRequestResult>;
  getAccounts(consentToken: string): Promise<YapilyAccount[]>;
}

/** @deprecated Use PisGateway */
export interface InitiatePaymentParams {
  amountCents: number;
  currency: string;
  beneficiaryIban: string;
  beneficiaryName: string;
  reference: string;
  redirectUri: string;
  paymentLinkId: string;
  idempotencyKey: string;
}

/** @deprecated Use PisGateway */
export interface InitiatePaymentResult {
  paymentId: string;
  redirectUrl: string;
}

/** @deprecated Use PisGateway */
export interface PisProvider {
  initiatePayment(params: InitiatePaymentParams): Promise<InitiatePaymentResult>;
  getPaymentStatus(paymentId: string, consentToken?: string): Promise<PaymentStatus>;
  verifyWebhookSignature(rawBody: string, signature: string): boolean;
}

export const PIS_GATEWAY = Symbol('PIS_GATEWAY');
export const AIS_GATEWAY = Symbol('AIS_GATEWAY');
/** @deprecated Use PIS_GATEWAY */
export const PIS_PROVIDER = Symbol('PIS_PROVIDER');
