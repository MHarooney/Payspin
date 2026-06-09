import { z } from 'zod';

export const SUPPORT_CATEGORIES = ['PAYMENT', 'ACCOUNT', 'CIRCLE', 'OTHER'] as const;

const supportBody = z.string().trim().min(1, 'Message cannot be empty').max(4000);

export const createSupportThreadSchema = z.object({
  subject: z.string().trim().max(120).optional(),
  category: z.enum(SUPPORT_CATEGORIES).optional(),
  body: supportBody,
  contextRef: z.string().trim().max(200).optional(),
});

export const sendSupportMessageSchema = z.object({
  body: supportBody,
});

export type CreateSupportThreadInput = z.infer<typeof createSupportThreadSchema>;
export type SendSupportMessageInput = z.infer<typeof sendSupportMessageSchema>;
