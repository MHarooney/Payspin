import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export class YapilyApiError extends Error {
  constructor(
    public readonly status: number,
    message: string,
  ) {
    super(message);
    this.name = 'YapilyApiError';
  }
}

@Injectable()
export class YapilyHttpClient {
  private readonly baseUrl: string;
  private readonly authHeader: string | null;

  constructor(private readonly config: ConfigService) {
    const key = this.config.get<string>('YAPILY_APP_KEY') ?? '';
    const secret = this.config.get<string>('YAPILY_APP_SECRET') ?? '';
    this.baseUrl = this.config.get<string>('YAPILY_BASE_URL') ?? 'https://api.yapily.com';
    this.authHeader =
      key && secret
        ? `Basic ${Buffer.from(`${key}:${secret}`).toString('base64')}`
        : null;
  }

  get isConfigured(): boolean {
    return this.authHeader !== null;
  }

  async request<T>(
    method: string,
    path: string,
    options?: {
      body?: unknown;
      headers?: Record<string, string>;
      idempotencyKey?: string;
    },
  ): Promise<T> {
    if (!this.authHeader) {
      throw new YapilyApiError(401, 'Yapily credentials not configured');
    }

    const headers: Record<string, string> = {
      Authorization: this.authHeader,
      'Content-Type': 'application/json',
      ...options?.headers,
    };
    if (options?.idempotencyKey) {
      headers['x-idempotency-key'] = options.idempotencyKey;
    }

    const response = await fetch(`${this.baseUrl}${path}`, {
      method,
      headers,
      body: options?.body ? JSON.stringify(options.body) : undefined,
    });

    if (!response.ok) {
      const text = await response.text();
      throw new YapilyApiError(response.status, text);
    }

    return response.json() as Promise<T>;
  }
}
