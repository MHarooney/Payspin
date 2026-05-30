import { Injectable } from '@nestjs/common';
import { PaymentStatus } from '@payspin/shared-types';
import {
  CreatePaymentParams,
  CreatePaymentResult,
  PaymentAuthRequestParams,
  PaymentAuthRequestResult,
  PisGateway,
} from '@payspin/pisp-provider';

@Injectable()
export class SandboxPisGateway implements PisGateway {
  async createPaymentAuthRequest(
    params: PaymentAuthRequestParams,
  ): Promise<PaymentAuthRequestResult> {
    const authRequestId = `sandbox_auth_${params.paymentRequest.paymentIdempotencyId}`;
    const authorisationUrl = `${params.callbackUrl}?sandboxPending=${authRequestId}`;
    return { authRequestId, authorisationUrl };
  }

  async createPayment(params: CreatePaymentParams): Promise<CreatePaymentResult> {
    const paymentId = `sandbox_${params.idempotencyKey}`;
    return { paymentId, status: PaymentStatus.COMPLETED };
  }

  async getPaymentStatus(): Promise<PaymentStatus> {
    return PaymentStatus.COMPLETED;
  }

  verifyWebhookSignature(): boolean {
    return true;
  }
}
