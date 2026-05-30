import { Body, Controller, Delete, Get, Param, Post, UseGuards } from '@nestjs/common';
import { CancelPaymentLinkUseCase } from '../../../application/use-cases/payment-links/cancel-payment-link.use-case';
import { CreatePaymentLinkUseCase } from '../../../application/use-cases/payment-links/create-payment-link.use-case';
import { GetPaymentLinkByIdUseCase } from '../../../application/use-cases/payment-links/get-payment-link-by-id.use-case';
import { ListPaymentLinksUseCase } from '../../../application/use-cases/payment-links/list-payment-links.use-case';
import { CurrentUser } from '../decorators/current-user.decorator';
import { JwtAuthGuard } from '../guards/jwt-auth.guard';
import { AuthenticatedUser } from '../guards/jwt.strategy';

@Controller('links')
@UseGuards(JwtAuthGuard)
export class PaymentLinksController {
  constructor(
    private readonly createLink: CreatePaymentLinkUseCase,
    private readonly listLinks: ListPaymentLinksUseCase,
    private readonly getLink: GetPaymentLinkByIdUseCase,
    private readonly cancelLink: CancelPaymentLinkUseCase,
  ) {}

  @Post()
  create(@CurrentUser() user: AuthenticatedUser, @Body() body: unknown) {
    return this.createLink.execute(user.userId, body);
  }

  @Get()
  list(@CurrentUser() user: AuthenticatedUser) {
    return this.listLinks.execute(user.userId);
  }

  @Get(':id')
  get(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.getLink.execute(user.userId, id);
  }

  @Delete(':id')
  cancel(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.cancelLink.execute(user.userId, id);
  }
}
