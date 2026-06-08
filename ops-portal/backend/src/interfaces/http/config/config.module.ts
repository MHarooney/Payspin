import { Module } from '@nestjs/common';
import { GetFeatureFlagsUseCase } from '../../../application/use-cases/config/get-feature-flags.use-case';
import { GetPlatformConfigUseCase } from '../../../application/use-cases/config/get-platform-config.use-case';
import { UpdateFeatureFlagUseCase } from '../../../application/use-cases/config/update-feature-flag.use-case';
import { UpdatePlatformConfigUseCase } from '../../../application/use-cases/config/update-platform-config.use-case';
import { ConfigController } from './config.controller';

@Module({
  controllers: [ConfigController],
  providers: [
    GetFeatureFlagsUseCase,
    UpdateFeatureFlagUseCase,
    GetPlatformConfigUseCase,
    UpdatePlatformConfigUseCase,
  ],
})
export class ConfigFeatureModule {}
