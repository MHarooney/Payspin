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

export type AdminLoginInput = z.infer<typeof adminLoginSchema>;
export type ListPaymentsQuery = z.infer<typeof listPaymentsQuerySchema>;
export type ListUsersQuery = z.infer<typeof listUsersQuerySchema>;
export type ListCirclesQuery = z.infer<typeof listCirclesQuerySchema>;
export type DashboardQuery = z.infer<typeof dashboardQuerySchema>;
export type ReportsQuery = z.infer<typeof reportsQuerySchema>;
export type UpdateFeatureFlagInput = z.infer<typeof updateFeatureFlagSchema>;
export type UpdatePlatformConfigInput = z.infer<typeof updatePlatformConfigSchema>;
export type KillSwitchInput = z.infer<typeof killSwitchSchema>;
export type SetUserAdminStateInput = z.infer<typeof setUserAdminStateSchema>;
export type GlobalSearchQuery = z.infer<typeof globalSearchSchema>;
export type TableRowsQuery = z.infer<typeof tableRowsQuerySchema>;
