import {
  BadRequestException,
  Controller,
  Headers,
  NotFoundException,
  Param,
  Post,
  UnauthorizedException,
} from '@nestjs/common';
import { SkipThrottle } from '@nestjs/throttler';
import { ConfigService } from '@nestjs/config';
import { ReconcilePaymentUseCase } from '../../../application/use-cases/payments/reconcile-payment.use-case';
import { ExpireStalePaymentsUseCase } from '../../../application/use-cases/payments/expire-stale-payments.use-case';
import { timingSafeEqual } from 'crypto';

@SkipThrottle()
@Controller('internal/payments')
export class InternalPaymentsController {
  constructor(
    private readonly reconcile: ReconcilePaymentUseCase,
    private readonly expireStale: ExpireStalePaymentsUseCase,
    private readonly config: ConfigService,
  ) {}

  @Post(':id/reconcile')
  async reconcileOne(
    @Param('id') id: string,
    @Headers('x-ops-internal-secret') secret?: string,
  ) {
    this.assertSecret(secret);
    try {
      const row = await this.reconcile.execute(id);
      return { id: row.id, status: row.status, yapilyPaymentId: row.yapilyPaymentId };
    } catch (e) {
      if (e instanceof NotFoundException) throw e;
      throw new BadRequestException('Reconciliation failed');
    }
  }

  @Post('sweep/stale')
  async sweepStale(@Headers('x-ops-internal-secret') secret?: string) {
    this.assertSecret(secret);
    const expired = await this.expireStale.execute();
    const sweep = await this.reconcile.reconcileAllInFlight();
    return { ...expired, ...sweep };
  }

  private assertSecret(provided?: string) {
    const expected = this.config.get<string>('OPS_INTERNAL_SECRET');
    if (!expected) {
      throw new UnauthorizedException('Internal reconciliation is not configured');
    }
    if (!provided || provided.length !== expected.length) {
      throw new UnauthorizedException('Invalid internal secret');
    }
    try {
      if (!timingSafeEqual(Buffer.from(provided), Buffer.from(expected))) {
        throw new UnauthorizedException('Invalid internal secret');
      }
    } catch {
      throw new UnauthorizedException('Invalid internal secret');
    }
  }
}
