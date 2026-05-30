import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { CompletePayerPaymentUseCase } from '../../../application/use-cases/payments/complete-payer-payment.use-case';
import { GetPaymentStatusUseCase } from '../../../application/use-cases/payments/get-payment-status.use-case';
import { GetPublicPaymentViewUseCase } from '../../../application/use-cases/payments/get-public-payment-view.use-case';
import { InitiatePayerPaymentUseCase } from '../../../application/use-cases/payments/initiate-payer-payment.use-case';

// Per-IP limit on public payer routes. Tight by default; tunable for ops/tests.
const PAY_THROTTLE_LIMIT = Number(process.env.PAY_THROTTLE_LIMIT ?? 10);

@Controller('pay/:code')
@Throttle({ default: { limit: PAY_THROTTLE_LIMIT, ttl: 60000 } })
export class PaymentsController {
  constructor(
    private readonly getPublicView: GetPublicPaymentViewUseCase,
    private readonly initiate: InitiatePayerPaymentUseCase,
    private readonly complete: CompletePayerPaymentUseCase,
    private readonly getStatus: GetPaymentStatusUseCase,
  ) {}

  @Get()
  view(@Param('code') code: string) {
    return this.getPublicView.execute(code);
  }

  @Post('initiate')
  start(@Param('code') code: string, @Body() body: unknown) {
    return this.initiate.execute(code, body);
  }

  @Post('complete')
  finish(@Param('code') code: string, @Body() body: unknown) {
    return this.complete.execute(code, body);
  }

  @Get('status/:paymentId')
  status(@Param('code') code: string, @Param('paymentId') paymentId: string) {
    return this.getStatus.execute(code, paymentId);
  }
}
