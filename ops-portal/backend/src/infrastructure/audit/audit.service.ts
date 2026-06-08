import { Injectable } from '@nestjs/common';
import { PrismaService } from '../persistence/prisma.module';

export interface AuditContext {
  adminUserId: string;
  adminEmail: string;
  ip?: string;
  userAgent?: string;
}

export interface AuditEntry {
  action: string;
  targetType?: string;
  targetId?: string;
  before?: unknown;
  after?: unknown;
}

/**
 * Append-only recorder for every mutating admin action. Failures here must never
 * mask the underlying mutation, but a missing audit row is a compliance gap, so
 * write failures are surfaced rather than swallowed.
 */
@Injectable()
export class AuditService {
  constructor(private readonly prisma: PrismaService) {}

  async record(ctx: AuditContext, entry: AuditEntry): Promise<void> {
    await this.prisma.adminAuditEvent.create({
      data: {
        adminUserId: ctx.adminUserId,
        adminEmail: ctx.adminEmail,
        action: entry.action,
        targetType: entry.targetType,
        targetId: entry.targetId,
        before: (entry.before ?? undefined) as never,
        after: (entry.after ?? undefined) as never,
        ip: ctx.ip,
        userAgent: ctx.userAgent,
      },
    });
  }
}
