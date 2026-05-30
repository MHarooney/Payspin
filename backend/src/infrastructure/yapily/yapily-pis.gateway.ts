import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHmac, timingSafeEqual } from 'crypto';
import { PaymentStatus } from '@payspin/shared-types';
import {
  CreatePaymentParams,
  CreatePaymentResult,
  PaymentAuthRequestParams,
  PaymentAuthRequestResult,
  PisGateway,
} from '@payspin/pisp-provider';
import { YapilyHttpClient } from './yapily-http.client';

interface YapilyMetaResponse<T> {
  data: T;
}

@Injectable()
export class YapilyPisGateway implements PisGateway {
  constructor(
    private readonly http: YapilyHttpClient,
    private readonly config: ConfigService,
  ) {}

  async createPaymentAuthRequest(
    params: PaymentAuthRequestParams,
  ): Promise<PaymentAuthRequestResult> {
    const institutionId =
      params.institutionId ??
      this.config.get<string>('YAPILY_DEFAULT_INSTITUTION') ??
      'yapily-mock';

    const res = await this.http.request<YapilyMetaResponse<{ id: string; authorisationUrl: string }>>(
      'POST',
      '/payment-auth-requests',
      {
        body: {
          applicationUserId: params.applicationUserId,
          institutionId,
          callback: params.callbackUrl,
          paymentRequest: params.paymentRequest,
        },
      },
    );

    return {
      authRequestId: res.data.id,
      authorisationUrl: res.data.authorisationUrl,
    };
  }

  async createPayment(params: CreatePaymentParams): Promise<CreatePaymentResult> {
    const res = await this.http.request<
      YapilyMetaResponse<{ id: string; status?: string }>
    >('POST', '/payments', {
      body: params.paymentRequest,
      headers: { Consent: params.consentToken },
      idempotencyKey: params.idempotencyKey,
    });

    return {
      paymentId: res.data.id,
      status: this.mapStatus(res.data.status),
    };
  }

  async getPaymentStatus(paymentId: string): Promise<PaymentStatus> {
    const res = await this.http.request<
      YapilyMetaResponse<{ status?: string }>
    >('GET', `/payments/${paymentId}/details`);

    return this.mapStatus(res.data.status);
  }

  verifyWebhookSignature(rawBody: string, signature: string): boolean {
    const secret = this.config.get<string>('YAPILY_WEBHOOK_SECRET') ?? '';
    if (!secret) {
      return process.env.NODE_ENV === 'development';
    }
    const expected = createHmac('sha256', secret).update(rawBody).digest('hex');
    try {
      return timingSafeEqual(Buffer.from(expected), Buffer.from(signature));
    } catch {
      return false;
    }
  }

  private mapStatus(status?: string): PaymentStatus {
    const s = (status ?? 'PENDING').toUpperCase();
    if (s.includes('COMPLETED') || s.includes('ACCEPTED')) return PaymentStatus.COMPLETED;
    if (s.includes('FAILED') || s.includes('REJECTED')) return PaymentStatus.FAILED;
    if (s.includes('PROCESSING')) return PaymentStatus.PROCESSING;
    return PaymentStatus.PENDING;
  }
}
