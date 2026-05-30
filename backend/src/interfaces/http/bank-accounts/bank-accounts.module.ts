import { Module } from '@nestjs/common';
import { YapilyModule } from '../../../infrastructure/yapily/yapily.module';
import { ConnectBankAccountUseCase } from '../../../application/use-cases/open-banking/connect-bank-account.use-case';
import { CompleteBankConnectionUseCase } from '../../../application/use-cases/open-banking/complete-bank-connection.use-case';
import { CreateBankAccountUseCase } from '../../../application/use-cases/bank-accounts/create-bank-account.use-case';
import { ListBankAccountsUseCase } from '../../../application/use-cases/bank-accounts/list-bank-accounts.use-case';
import { GetDecryptedIbanUseCase } from '../../../application/use-cases/bank-accounts/get-decrypted-iban.use-case';
import { BankAccountsController } from './bank-accounts.controller';

@Module({
  imports: [YapilyModule],
  controllers: [BankAccountsController],
  providers: [
    CreateBankAccountUseCase,
    ListBankAccountsUseCase,
    GetDecryptedIbanUseCase,
    ConnectBankAccountUseCase,
    CompleteBankConnectionUseCase,
  ],
  exports: [GetDecryptedIbanUseCase],
})
export class BankAccountsModule {}
