import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { ConnectBankAccountUseCase } from '../../../application/use-cases/open-banking/connect-bank-account.use-case';
import { CompleteBankConnectionUseCase } from '../../../application/use-cases/open-banking/complete-bank-connection.use-case';
import { CreateBankAccountUseCase } from '../../../application/use-cases/bank-accounts/create-bank-account.use-case';
import { ListBankAccountsUseCase } from '../../../application/use-cases/bank-accounts/list-bank-accounts.use-case';
import { CurrentUser } from '../decorators/current-user.decorator';
import { JwtAuthGuard } from '../guards/jwt-auth.guard';
import { AuthenticatedUser } from '../guards/jwt.strategy';

@Controller('bank-accounts')
export class BankAccountsController {
  constructor(
    private readonly createAccount: CreateBankAccountUseCase,
    private readonly listAccounts: ListBankAccountsUseCase,
    private readonly connect: ConnectBankAccountUseCase,
    private readonly completeConnect: CompleteBankConnectionUseCase,
  ) {}

  @Get()
  @UseGuards(JwtAuthGuard)
  list(@CurrentUser() user: AuthenticatedUser) {
    return this.listAccounts.execute(user.userId);
  }

  @Post()
  @UseGuards(JwtAuthGuard)
  create(@CurrentUser() user: AuthenticatedUser, @Body() body: unknown) {
    return this.createAccount.execute(user.userId, body);
  }

  @Post('connect')
  @UseGuards(JwtAuthGuard)
  startConnect(
    @CurrentUser() user: AuthenticatedUser,
    @Body() body: { institutionId?: string },
  ) {
    return this.connect.execute(user.userId, body);
  }

  @Post('connect/complete')
  @UseGuards(JwtAuthGuard)
  finishConnect(
    @CurrentUser() user: AuthenticatedUser,
    @Body()
    body: { connectionId: string; consentToken: string; expectedIban?: string },
  ) {
    return this.completeConnect.execute(user.userId, body);
  }
}
