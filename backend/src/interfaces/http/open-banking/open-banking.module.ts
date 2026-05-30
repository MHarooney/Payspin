import { Module } from '@nestjs/common';
import { YapilyModule } from '../../../infrastructure/yapily/yapily.module';
import { ListInstitutionsUseCase } from '../../../application/use-cases/open-banking/list-institutions.use-case';
import { OpenBankingController } from './open-banking.controller';

@Module({
  imports: [YapilyModule],
  controllers: [OpenBankingController],
  providers: [ListInstitutionsUseCase],
})
export class OpenBankingModule {}
