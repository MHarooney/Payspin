import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  Patch,
  Post,
  Query,
  Res,
  UseGuards,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Response } from 'express';
import { ConnectBankAccountUseCase } from '../../../application/use-cases/open-banking/connect-bank-account.use-case';
import { CompleteBankConnectionUseCase } from '../../../application/use-cases/open-banking/complete-bank-connection.use-case';
import { CreateBankAccountUseCase } from '../../../application/use-cases/bank-accounts/create-bank-account.use-case';
import { ListBankAccountsUseCase } from '../../../application/use-cases/bank-accounts/list-bank-accounts.use-case';
import { SetPrimaryBankAccountUseCase } from '../../../application/use-cases/bank-accounts/set-primary-bank-account.use-case';
import { DeleteBankAccountUseCase } from '../../../application/use-cases/bank-accounts/delete-bank-account.use-case';
import { CurrentUser } from '../decorators/current-user.decorator';
import { JwtAuthGuard } from '../guards/jwt-auth.guard';
import { AuthenticatedUser } from '../guards/jwt.strategy';

const DEFAULT_MOBILE_REDIRECT = 'payspin://bank-callback';

@Controller('bank-accounts')
export class BankAccountsController {
  constructor(
    private readonly createAccount: CreateBankAccountUseCase,
    private readonly listAccounts: ListBankAccountsUseCase,
    private readonly setPrimary: SetPrimaryBankAccountUseCase,
    private readonly deleteAccount: DeleteBankAccountUseCase,
    private readonly connect: ConnectBankAccountUseCase,
    private readonly completeConnect: CompleteBankConnectionUseCase,
    private readonly config: ConfigService,
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

  @Patch(':id/primary')
  @UseGuards(JwtAuthGuard)
  makePrimary(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.setPrimary.execute(user.userId, id);
  }

  @Delete(':id')
  @HttpCode(204)
  @UseGuards(JwtAuthGuard)
  async remove(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    await this.deleteAccount.execute(user.userId, id);
  }

  @Post('connect')
  @UseGuards(JwtAuthGuard)
  startConnect(@CurrentUser() user: AuthenticatedUser, @Body() body: unknown) {
    return this.connect.execute(user.userId, body);
  }

  @Post('connect/complete')
  @UseGuards(JwtAuthGuard)
  finishConnect(@CurrentUser() user: AuthenticatedUser, @Body() body: unknown) {
    return this.completeConnect.execute(user.userId, body);
  }

  /**
   * Yapily redirects here after the user authorises at their bank (this URL is
   * the one registered in the Yapily console). We capture the consent
   * one-time-token and bounce into the mobile app via a custom-scheme deep link
   * so it can call `connect/complete`. Unauthenticated by design — Yapily, not
   * the app, performs this redirect.
   */
  @Get('connect/callback')
  connectCallback(
    @Query('consent') consent: string | undefined,
    @Query('consentToken') consentToken: string | undefined,
    @Query('error') error: string | undefined,
    @Res() res: Response,
  ) {
    const redirectBase =
      this.config.get<string>('MOBILE_CONNECT_REDIRECT') ?? DEFAULT_MOBILE_REDIRECT;
    const target = new URL(redirectBase);

    if (error) {
      target.searchParams.set('error', error);
    } else {
      // Sandbox redirects carry no real consent; forward a placeholder so the
      // end-to-end flow still completes locally.
      target.searchParams.set('consent', consent ?? consentToken ?? 'sandbox-consent');
    }

    res.redirect(302, target.toString());
  }
}
