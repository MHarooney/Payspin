import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { createHmac } from 'crypto';
import { YapilyPisGateway } from '../src/infrastructure/yapily/yapily-pis.gateway';

function gatewayWith(env: Record<string, string | undefined>) {
  const config = { get: (k: string) => env[k] } as any;
  return new YapilyPisGateway({} as any, config);
}

function sign(secret: string, body: string) {
  return createHmac('sha256', secret).update(body).digest('hex');
}

describe('YapilyPisGateway.verifyWebhookSignature', () => {
  const body = '{"id":"evt-1","status":"COMPLETED"}';

  it('accepts a valid HMAC-SHA256 signature', () => {
    const gw = gatewayWith({ YAPILY_WEBHOOK_SECRET: 'topsecret' });
    assert.equal(gw.verifyWebhookSignature(body, sign('topsecret', body)), true);
  });

  it('rejects an invalid signature', () => {
    const gw = gatewayWith({ YAPILY_WEBHOOK_SECRET: 'topsecret' });
    assert.equal(gw.verifyWebhookSignature(body, 'deadbeef'), false);
  });

  it('rejects a signature made with the wrong secret', () => {
    const gw = gatewayWith({ YAPILY_WEBHOOK_SECRET: 'topsecret' });
    assert.equal(gw.verifyWebhookSignature(body, sign('not-the-secret', body)), false);
  });

  it('fails closed when no secret is configured (non-development)', () => {
    const prev = process.env.NODE_ENV;
    process.env.NODE_ENV = 'production';
    try {
      const gw = gatewayWith({ YAPILY_WEBHOOK_SECRET: undefined });
      assert.equal(gw.verifyWebhookSignature(body, 'anything'), false);
    } finally {
      process.env.NODE_ENV = prev;
    }
  });
});
