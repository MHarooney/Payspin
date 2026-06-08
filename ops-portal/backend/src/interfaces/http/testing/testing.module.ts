import { Module } from '@nestjs/common';
import { GetTestingScenariosUseCase, RunTestingScenariosUseCase } from '../../../application/use-cases/testing/run-testing-scenarios.use-case';
import { SystemModule } from '../system/system.module';
import { UsersModule } from '../users/users.module';
import { PaymentLinksModule } from '../payment-links/payment-links.module';
import { TestingController } from './testing.controller';

@Module({
  imports: [SystemModule, UsersModule, PaymentLinksModule],
  controllers: [TestingController],
  providers: [GetTestingScenariosUseCase, RunTestingScenariosUseCase],
})
export class TestingModule {}
