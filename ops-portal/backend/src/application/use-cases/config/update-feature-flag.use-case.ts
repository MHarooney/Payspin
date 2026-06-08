import { Injectable, NotFoundException } from '@nestjs/common';
import { FeatureFlagDto } from '@payspin/shared-types';
import { updateFeatureFlagSchema } from '@payspin/validators';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { AuditService } from '../../../infrastructure/audit/audit.service';
import { AuditAction } from '../../../domain/constants';
import { AdminRequestContext } from '../../../interfaces/http/decorators/current-admin.decorator';
import { toFeatureFlagDto } from './config.mapper';

@Injectable()
export class UpdateFeatureFlagUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
  ) {}

  async execute(key: string, body: unknown, ctx: AdminRequestContext): Promise<FeatureFlagDto> {
    const { enabled } = updateFeatureFlagSchema.parse(body);
    const existing = await this.prisma.featureFlag.findUnique({ where: { key } });
    if (!existing) {
      throw new NotFoundException('Feature flag not found');
    }

    const updated = await this.prisma.featureFlag.update({
      where: { key },
      data: { enabled, updatedByEmail: ctx.email },
    });

    await this.audit.record(
      { adminUserId: ctx.adminUserId, adminEmail: ctx.email, ip: ctx.ip, userAgent: ctx.userAgent },
      {
        action: AuditAction.FLAG_TOGGLE,
        targetType: 'feature_flag',
        targetId: key,
        before: { enabled: existing.enabled },
        after: { enabled },
      },
    );

    return toFeatureFlagDto(updated);
  }
}
