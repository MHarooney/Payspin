import { FeatureFlagDto, PlatformConfigDto } from '@payspin/shared-types';
import type { FeatureFlag, PlatformConfig } from '@prisma/client';

export function toFeatureFlagDto(f: FeatureFlag): FeatureFlagDto {
  return {
    key: f.key,
    label: f.label,
    description: f.description,
    enabled: f.enabled,
    category: f.category,
    updatedByEmail: f.updatedByEmail,
    updatedAt: f.updatedAt.toISOString(),
  };
}

export function toPlatformConfigDto(c: PlatformConfig): PlatformConfigDto {
  return {
    key: c.key,
    label: c.label,
    value: c.value,
    valueType: c.valueType,
    group: c.group,
    description: c.description,
    updatedByEmail: c.updatedByEmail,
    updatedAt: c.updatedAt.toISOString(),
  };
}
