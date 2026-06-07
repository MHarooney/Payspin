import { Module } from '@nestjs/common';
import { ListAuditEventsUseCase } from '../../../application/use-cases/audit/list-audit-events.use-case';
import { ActivateKillSwitchUseCase } from '../../../application/use-cases/kill-switch/activate-kill-switch.use-case';
import { GetKillSwitchStateUseCase } from '../../../application/use-cases/kill-switch/get-kill-switch-state.use-case';
import { GlobalSearchUseCase } from '../../../application/use-cases/search/global-search.use-case';
import { PlatformController } from './platform.controller';

@Module({
  controllers: [PlatformController],
  providers: [
    GetKillSwitchStateUseCase,
    ActivateKillSwitchUseCase,
    ListAuditEventsUseCase,
    GlobalSearchUseCase,
  ],
})
export class PlatformModule {}
