import { Injectable } from '@nestjs/common';
import { PlatformConfigDto } from '@payspin/shared-types';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { toPlatformConfigDto } from './config.mapper';

@Injectable()
export class GetPlatformConfigUseCase {
  constructor(private readonly prisma: PrismaService) {}

  async execute(): Promise<PlatformConfigDto[]> {
    const rows = await this.prisma.platformConfig.findMany({
      orderBy: [{ group: 'asc' }, { label: 'asc' }],
    });
    return rows.map(toPlatformConfigDto);
  }
}
