import { Module } from '@nestjs/common';
import { GetSystemHealthUseCase } from '../../../application/use-cases/system/get-system-health.use-case';
import { SystemController } from './system.controller';

@Module({
  controllers: [SystemController],
  providers: [GetSystemHealthUseCase],
})
export class SystemModule {}
