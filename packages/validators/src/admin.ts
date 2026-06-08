import { z } from 'zod';

export const adminLoginSchema = z.object({
  email: z.string().email().max(255),
  password: z.string().min(1).max(128),
});

export const paginationSchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  pageSize: z.coerce.number().int().min(1).max(100).default(20),
});

export const listPaymentsQuerySchema = paginationSchema.extend({
  status: z
    .enum([
      'AWAITING_AUTHORIZATION',
      'PENDING',
      'PROCESSING',
      'COMPLETED',
      'FAILED',
      'CANCELLED',
    ])
    .optional(),
  search: z.string().trim().max(120).optional(),
});

export const listUsersQuerySchema = paginationSchema.extend({
  status: z.enum(['ACTIVE', 'FROZEN', 'SUSPENDED', 'BLOCKED']).optional(),
  search: z.string().trim().max(120).optional(),
});

export const listCirclesQuerySchema = paginationSchema.extend({
  filter: z.enum(['all', 'active', 'risk', 'completed']).default('all'),
  search: z.string().trim().max(120).optional(),
});

export const dashboardQuerySchema = z.object({
  period: z.enum(['today', 'week', 'month']).default('today'),
});

export const reportsQuerySchema = z.object({
  granularity: z.enum(['hourly', 'daily', 'weekly', 'monthly']).default('hourly'),
});

export const updateFeatureFlagSchema = z.object({
  enabled: z.boolean(),
});

export const updatePlatformConfigSchema = z.object({
  value: z.string().min(1).max(500),
});

export const killSwitchSchema = z.object({
  active: z.boolean(),
  reason: z.string().trim().min(8, 'A reason of at least 8 characters is required').max(500),
  totpCode: z.string().trim().max(12).optional(),
});

export const setUserAdminStateSchema = z
  .object({
    status: z.enum(['ACTIVE', 'FROZEN', 'SUSPENDED', 'BLOCKED']).optional(),
    kycStatus: z.enum(['PENDING', 'VERIFIED', 'REJECTED', 'ONBOARDING']).optional(),
    kycTier: z.enum(['KYC1', 'KYC2']).optional(),
    riskLevel: z.enum(['LOW', 'MEDIUM', 'HIGH']).optional(),
    reason: z.string().trim().max(500).optional(),
  })
  .refine(
    (d) =>
      d.status !== undefined ||
      d.kycStatus !== undefined ||
      d.kycTier !== undefined ||
      d.riskLevel !== undefined,
    { message: 'Provide at least one field to update' },
  );

export const globalSearchSchema = z.object({
  q: z.string().trim().min(1).max(120),
});

export const tableRowsQuerySchema = paginationSchema.extend({
  pageSize: z.coerce.number().int().min(1).max(50).default(20),
});

// ---- User CRUD schemas ----
export const createUserAdminSchema = z.object({
  email: z.string().email().max(255),
  displayName: z.string().trim().max(100).optional(),
  phoneE164: z.string().regex(/^\+[1-9]\d{6,14}$/, 'Invalid E.164 phone').optional(),
  tempPassword: z.string().min(8).max(128).optional(),
});

export const patchUserAdminSchema = z.object({
  displayName: z.string().trim().max(100).optional(),
  phoneE164: z.string().regex(/^\+[1-9]\d{6,14}$/, 'Invalid E.164 phone').optional().nullable(),
  email: z.string().email().max(255).optional(), // SUPER_ADMIN only
}).refine((d) => Object.keys(d).length > 0, { message: 'Provide at least one field' });

export const resetPasswordAdminSchema = z.object({
  tempPassword: z.string().min(8).max(128),
});

// ---- Payment link schemas ----
export const patchPaymentLinkAdminSchema = z.object({
  action: z.enum(['cancel', 'extend']),
  expiresAt: z.string().datetime().optional(), // required for 'extend'
  reason: z.string().trim().max(500).optional(),
}).refine(
  (d) => d.action !== 'extend' || !!d.expiresAt,
  { message: 'expiresAt required for extend', path: ['expiresAt'] },
);

// ---- Create payment link on behalf of user ----
export const createPaymentLinkOpsSchema = z.object({
  payeeUserId: z.string().uuid(),
  amountCents: z.number().int().min(1).optional(),
  currency: z.string().length(3).default('EUR'),
  description: z.string().trim().max(255).optional(),
});

// ---- Compliance / Dispute ----
export const patchComplianceAlertSchema = z.object({
  status: z.enum(['OPEN', 'INVESTIGATING', 'CLEARED']),
  note: z.string().trim().max(500).optional(),
});

export const patchDisputeAdminSchema = z.object({
  status: z.enum(['OPEN', 'INVESTIGATING', 'RESOLVED', 'CLOSED']),
  note: z.string().trim().max(500).optional(),
});

// ---- Support messages ----
export const createSupportMessageSchema = z.object({
  body: z.string().trim().min(1).max(2000),
});

export const patchSupportThreadSchema = z.object({
  status: z.enum(['OPEN', 'RESOLVED']),
});

// ---- Admin staff CRUD ----
export const createAdminStaffSchema = z.object({
  email: z.string().email().max(255),
  displayName: z.string().trim().max(100).optional(),
  role: z.enum(['SUPER_ADMIN', 'OPS', 'SUPPORT', 'READ_ONLY']),
  tempPassword: z.string().min(8).max(128),
});

export const patchAdminStaffSchema = z.object({
  displayName: z.string().trim().max(100).optional(),
  role: z.enum(['SUPER_ADMIN', 'OPS', 'SUPPORT', 'READ_ONLY']).optional(),
  isActive: z.boolean().optional(),
}).refine((d) => Object.keys(d).length > 0, { message: 'Provide at least one field' });

// ---- List queries with deletedAt filter ----
export const listUsersAdminQuerySchema = paginationSchema.extend({
  status: z.enum(['ACTIVE', 'FROZEN', 'SUSPENDED', 'BLOCKED']).optional(),
  search: z.string().trim().max(120).optional(),
  includeDeleted: z.coerce.boolean().default(false),
});

export type AdminLoginInput = z.infer<typeof adminLoginSchema>;
export type ListPaymentsQuery = z.infer<typeof listPaymentsQuerySchema>;
export type ListUsersQuery = z.infer<typeof listUsersQuerySchema>;
export type ListUsersAdminQuery = z.infer<typeof listUsersAdminQuerySchema>;
export type ListCirclesQuery = z.infer<typeof listCirclesQuerySchema>;
export type DashboardQuery = z.infer<typeof dashboardQuerySchema>;
export type ReportsQuery = z.infer<typeof reportsQuerySchema>;
export type UpdateFeatureFlagInput = z.infer<typeof updateFeatureFlagSchema>;
export type UpdatePlatformConfigInput = z.infer<typeof updatePlatformConfigSchema>;
export type KillSwitchInput = z.infer<typeof killSwitchSchema>;
export type SetUserAdminStateInput = z.infer<typeof setUserAdminStateSchema>;
export type GlobalSearchQuery = z.infer<typeof globalSearchSchema>;
export type TableRowsQuery = z.infer<typeof tableRowsQuerySchema>;
export type CreateUserAdminInput = z.infer<typeof createUserAdminSchema>;
export type PatchUserAdminInput = z.infer<typeof patchUserAdminSchema>;
export type ResetPasswordAdminInput = z.infer<typeof resetPasswordAdminSchema>;
export type PatchPaymentLinkAdminInput = z.infer<typeof patchPaymentLinkAdminSchema>;
export type PatchComplianceAlertInput = z.infer<typeof patchComplianceAlertSchema>;
export type PatchDisputeAdminInput = z.infer<typeof patchDisputeAdminSchema>;
export type CreateSupportMessageInput = z.infer<typeof createSupportMessageSchema>;
export type PatchSupportThreadInput = z.infer<typeof patchSupportThreadSchema>;
export type CreateAdminStaffInput = z.infer<typeof createAdminStaffSchema>;
export type PatchAdminStaffInput = z.infer<typeof patchAdminStaffSchema>;

