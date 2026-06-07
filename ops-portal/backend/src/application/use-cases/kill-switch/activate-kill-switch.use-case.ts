import { Injectable } from '@nestjs/common';
import { KillSwitchState } from '@payspin/shared-types';
import { killSwitchSchema } from '@payspin/validators';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { AuditService } from '../../../infrastructure/audit/audit.service';
import { AuditAction, KILL_SWITCH_FLAG_KEY } from '../../../domain/constants';
import { AdminRequestContext } from '../../../interfaces/http/decorators/current-admin.decorator';

/**
 * Toggles the platform-wide kill switch (a privileged FeatureFlag). A reason is
 * mandatory and recorded to the audit trail. The 2FA / TOTP gate is a documented
 * stub — the code field is accepted and logged but not yet verified.
 */
@Injectable()
export class ActivateKillSwitchUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
  ) {}

  async execute(body: unknown, ctx: AdminRequestContext): Promise<KillSwitchState> {
    const { active, reason, totpCode } = killSwitchSchema.parse(body);

    const before = await this.prisma.featureFlag.findUnique({
      where: { key: KILL_SWITCH_FLAG_KEY },
    });

    const flag = await this.prisma.featureFlag.upsert({
      where: { key: KILL_SWITCH_FLAG_KEY },
      create: {
        key: KILL_SWITCH_FLAG_KEY,
        label: 'Platform kill switch',
        description: 'Pauses all new transactions platform-wide.',
        category: 'platform',
        enabled: active,
        updatedByEmail: ctx.email,
      },
      update: { enabled: active, updatedByEmail: ctx.email },
    });

    await this.audit.record(
      { adminUserId: ctx.adminUserId, adminEmail: ctx.email, ip: ctx.ip, userAgent: ctx.userAgent },
      {
        action: active ? AuditAction.KILL_SWITCH_ON : AuditAction.KILL_SWITCH_OFF,
        targetType: 'feature_flag',
        targetId: KILL_SWITCH_FLAG_KEY,
        before: { enabled: before?.enabled ?? false },
        after: { enabled: active, reason, twoFactorProvided: Boolean(totpCode) },
      },
    );

    return {
      active: flag.enabled,
      updatedByEmail: flag.updatedByEmail,
      updatedAt: flag.updatedAt.toISOString(),
    };
  }
}
