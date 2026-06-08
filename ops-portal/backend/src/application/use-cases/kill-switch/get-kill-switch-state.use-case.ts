import { Injectable } from '@nestjs/common';
import { KillSwitchState } from '@payspin/shared-types';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { KILL_SWITCH_FLAG_KEY } from '../../../domain/constants';

@Injectable()
export class GetKillSwitchStateUseCase {
  constructor(private readonly prisma: PrismaService) {}

  async execute(): Promise<KillSwitchState> {
    const flag = await this.prisma.featureFlag.findUnique({
      where: { key: KILL_SWITCH_FLAG_KEY },
    });
    return {
      active: flag?.enabled ?? false,
      updatedByEmail: flag?.updatedByEmail ?? null,
      updatedAt: flag?.updatedAt.toISOString() ?? null,
    };
  }
}
