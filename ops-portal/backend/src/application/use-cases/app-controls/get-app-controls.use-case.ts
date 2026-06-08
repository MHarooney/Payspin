import { Injectable } from '@nestjs/common';
import { AppControlsResponse } from '@payspin/shared-types';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { toPlatformConfigDto } from '../config/config.mapper';

/**
 * Phase 2: remote configuration for the consumer app. Modules are FeatureFlags in
 * the `app` category; defaults are PlatformConfig rows in the `app` group. The
 * banner is read from a dedicated config key.
 */
@Injectable()
export class GetAppControlsUseCase {
  constructor(private readonly prisma: PrismaService) {}

  async execute(): Promise<AppControlsResponse> {
    const [flags, defaults, banner] = await Promise.all([
      this.prisma.featureFlag.findMany({ where: { category: 'app' }, orderBy: { label: 'asc' } }),
      this.prisma.platformConfig.findMany({ where: { group: 'app' }, orderBy: { label: 'asc' } }),
      this.prisma.platformConfig.findUnique({ where: { key: 'app_banner_text' } }),
    ]);

    return {
      modules: flags.map((f) => ({
        key: f.key,
        label: f.label,
        description: f.description ?? '',
        enabled: f.enabled,
      })),
      banner: banner ? { text: banner.value, tone: 'info' } : null,
      defaults: defaults.map(toPlatformConfigDto),
      preview: true,
    };
  }
}
