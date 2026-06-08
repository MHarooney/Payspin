import { z } from 'zod';
import { normalizeIban, validateIban } from './iban';

export { IBAN_LENGTHS, ibanCountry, normalizeIban, validateIban, validateIbanMod97 } from './iban';
export * from './admin';

export const createBankAccountSchema = z.object({
  iban: z
    .string()
    .min(15)
    .max(34)
    .transform((v) => normalizeIban(v))
    .refine((v) => validateIban(v) === null, { message: 'Invalid IBAN' }),
  accountHolder: z.string().min(2).max(70),
  bankName: z.string().max(100).optional(),
});

export const registerSchema = z.object({
  email: z.string().email().max(255),
  password: z.string().min(8).max(128),
  displayName: z.string().min(1).max(100).optional(),
});

export const loginSchema = z.object({
  email: z.string().email().max(255),
  password: z.string().min(1).max(128),
});

export const updateUserSchema = z.object({
  displayName: z.string().min(1).max(100).optional(),
});

export const registerDeviceTokenSchema = z.object({
  fcmToken: z.string().min(8).max(4096),
  platform: z.enum(['ios', 'android', 'web', 'unknown']).default('unknown'),
});

export const listNotificationsSchema = z.object({
  cursor: z.string().max(64).optional(),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

export const verifyPhoneSchema = z.object({
  idToken: z.string().min(10).max(8192),
});

/**
 * Sign in (or auto-register) using a Firebase Phone Auth ID token. The verified
 * E.164 number inside the token is the account identity, so the same phone
 * always resolves to the same Payspin account — no duplicate accounts when a
 * user re-onboards. [displayName] is only applied when creating a new account.
 */
export const phoneSignInSchema = z.object({
  idToken: z.string().min(10).max(8192),
  displayName: z.string().min(1).max(100).optional(),
});

export const MAX_AMOUNT_CENTS = 999_999_999;

export const createPaymentLinkSchema = z.object({
  amountCents: z.number().int().positive().max(MAX_AMOUNT_CENTS).optional(),
  currency: z.string().length(3).default('EUR'),
  description: z.string().max(140).optional(),
  linkType: z.enum(['SINGLE', 'MULTI']).default('SINGLE'),
  maxUses: z.number().int().positive().optional(),
  expiresInDays: z.number().int().min(1).max(365).optional(),
  /** Optional: pay into a specific IBAN. Omitted → the user's primary account. */
  bankAccountId: z.string().uuid().optional(),
});

export const initiatePaymentSchema = z.object({
  amountCents: z.number().int().positive().max(MAX_AMOUNT_CENTS).optional(),
  /**
   * Optional note from the payer. Capped at the SEPA reference length (35
   * chars) and trimmed; surfaced on the payer's bank statement and to the payee.
   */
  payerMessage: z
    .string()
    .trim()
    .max(35)
    .transform((v) => (v.length === 0 ? undefined : v))
    .optional(),
});

export const completePaymentSchema = z.object({
  paymentId: z.string().min(1).max(64),
  consentToken: z.string().min(1).max(4096).optional(),
});

export const connectBankAccountSchema = z.object({
  institutionId: z.string().min(1).max(120).optional(),
});

export const completeBankConnectionSchema = z.object({
  connectionId: z.string().min(1).max(120),
  consentToken: z.string().min(1).max(4096),
  expectedIban: z.string().min(15).max(34).optional(),
});

export const listInstitutionsSchema = z.object({
  country: z
    .string()
    .regex(/^[A-Za-z]{2}$/, 'country must be a 2-letter ISO code')
    .optional(),
});

export const createCircleSchema = z.object({
  name: z.string().min(2).max(80),
  contributionCents: z.number().int().positive().max(MAX_AMOUNT_CENTS),
  cycleDurationDays: z.number().int().min(7).max(365),
  memberCount: z.number().int().min(2).max(50),
});

export const joinCircleSchema = z.object({
  inviteCode: z.string().min(4).max(12),
});

export const updateCircleMemberSchema = z
  .object({
    payoutOrder: z.number().int().min(0).optional(),
    status: z.enum(['ACTIVE', 'REMOVED']).optional(),
  })
  .refine((data) => data.payoutOrder !== undefined || data.status !== undefined, {
    message: 'Provide payoutOrder and/or status',
  });

export type RegisterInput = z.infer<typeof registerSchema>;
export type LoginInput = z.infer<typeof loginSchema>;
export type RegisterDeviceTokenInput = z.infer<typeof registerDeviceTokenSchema>;
export type ListNotificationsInput = z.infer<typeof listNotificationsSchema>;
export type VerifyPhoneInput = z.infer<typeof verifyPhoneSchema>;
export type PhoneSignInInput = z.infer<typeof phoneSignInSchema>;
export type CreateBankAccountInput = z.infer<typeof createBankAccountSchema>;
export type UpdateUserInput = z.infer<typeof updateUserSchema>;
export type CreatePaymentLinkInput = z.infer<typeof createPaymentLinkSchema>;
export type InitiatePaymentInput = z.infer<typeof initiatePaymentSchema>;
export type CompletePaymentInput = z.infer<typeof completePaymentSchema>;
export type ConnectBankAccountInput = z.infer<typeof connectBankAccountSchema>;
export type CompleteBankConnectionInput = z.infer<typeof completeBankConnectionSchema>;
export type CreateCircleInput = z.infer<typeof createCircleSchema>;
export type JoinCircleInput = z.infer<typeof joinCircleSchema>;
export type UpdateCircleMemberInput = z.infer<typeof updateCircleMemberSchema>;
