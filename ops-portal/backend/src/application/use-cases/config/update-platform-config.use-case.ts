import { Injectable, NotFoundException } from '@nestjs/common';
import { PlatformConfigDto } from '@payspin/shared-types';
import { updatePlatformConfigSchema } from '@payspin/validators';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { AuditService } from '../../../infrastructure/audit/audit.service';
import { AuditAction } from '../../../domain/constants';
import { AdminRequestContext } from '../../../interfaces/http/decorators/current-admin.decorator';
import { toPlatformConfigDto } from './config.mapper';

@Injectable()
export class UpdatePlatformConfigUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
  ) {}

  async execute(key: string, body: unknown, ctx: AdminRequestContext): Promise<PlatformConfigDto> {
    const { value } = updatePlatformConfigSchema.parse(body);
    const existing = await this.prisma.platformConfig.findUnique({ where: { key } });
    if (!existing) {
      throw new NotFoundException('Config key not found');
    }

    const updated = await this.prisma.platformConfig.update({
      where: { key },
      data: { value, updatedByEmail: ctx.email },
    });

    await this.audit.record(
      { adminUserId: ctx.adminUserId, adminEmail: ctx.email, ip: ctx.ip, userAgent: ctx.userAgent },
      {
        action: AuditAction.CONFIG_UPDATE,
        targetType: 'platform_config',
        targetId: key,
        before: { value: existing.value },
        after: { value },
      },
    );

    return toPlatformConfigDto(updated);
  }
}
