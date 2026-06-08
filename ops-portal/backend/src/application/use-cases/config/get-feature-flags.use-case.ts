import { Injectable } from '@nestjs/common';
import { FeatureFlagDto } from '@payspin/shared-types';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { KILL_SWITCH_FLAG_KEY } from '../../../domain/constants';
import { toFeatureFlagDto } from './config.mapper';

@Injectable()
export class GetFeatureFlagsUseCase {
  constructor(private readonly prisma: PrismaService) {}

  async execute(): Promise<FeatureFlagDto[]> {
    const flags = await this.prisma.featureFlag.findMany({
      where: { key: { not: KILL_SWITCH_FLAG_KEY } },
      orderBy: [{ category: 'asc' }, { label: 'asc' }],
    });
    return flags.map(toFeatureFlagDto);
  }
}
