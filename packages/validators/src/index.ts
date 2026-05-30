import { z } from 'zod';
import { normalizeIban, validateIban } from './iban';

export { IBAN_LENGTHS, normalizeIban, validateIban, validateIbanMod97 } from './iban';

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

export const createPaymentLinkSchema = z.object({
  amountCents: z.number().int().positive().max(999_999_999).optional(),
  currency: z.string().length(3).default('EUR'),
  description: z.string().max(140).optional(),
  linkType: z.enum(['SINGLE', 'MULTI']).default('SINGLE'),
  maxUses: z.number().int().positive().optional(),
  expiresInDays: z.number().int().min(1).max(365).optional(),
});

export type RegisterInput = z.infer<typeof registerSchema>;
export type LoginInput = z.infer<typeof loginSchema>;
export type CreateBankAccountInput = z.infer<typeof createBankAccountSchema>;
export type UpdateUserInput = z.infer<typeof updateUserSchema>;
export type CreatePaymentLinkInput = z.infer<typeof createPaymentLinkSchema>;
