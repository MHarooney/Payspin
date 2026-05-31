import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { PaymentStatus } from '@payspin/shared-types';
import {
  isSandboxAutoSettleEnabled,
  resolveSandboxPaymentStatus,
} from '../src/domain/utils/sandbox-settlement';

describe('sandbox-settlement', () => {
  it('auto-settles pending sandbox payments when enabled', () => {
    assert.equal(
      resolveSandboxPaymentStatus(PaymentStatus.PENDING, {
        autoSettle: true,
        submittedToYapily: true,
      }),
      PaymentStatus.COMPLETED,
    );
  });

  it('does not auto-settle when disabled', () => {
    assert.equal(
      resolveSandboxPaymentStatus(PaymentStatus.PENDING, {
        autoSettle: false,
        submittedToYapily: true,
      }),
      PaymentStatus.PENDING,
    );
  });

  it('detects sandbox institution from env', () => {
    assert.equal(
      isSandboxAutoSettleEnabled({ YAPILY_DEFAULT_INSTITUTION: 'modelo-sandbox' }),
      true,
    );
    assert.equal(
      isSandboxAutoSettleEnabled({
        YAPILY_DEFAULT_INSTITUTION: 'ing-nl',
        PAYSPIN_SANDBOX_AUTO_SETTLE: 'false',
      }),
      false,
    );
  });
});
