import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import {
  hasReachedMaxUses,
  isPayableStatus,
  nextStatusAfterPayment,
} from '../src/domain/utils/payment-link-state';

describe('payment-link-state', () => {
  it('treats ACTIVE and COLLECTING as payable', () => {
    assert.equal(isPayableStatus('ACTIVE' as any), true);
    assert.equal(isPayableStatus('COLLECTING' as any), true);
  });

  it('treats terminal states as not payable', () => {
    assert.equal(isPayableStatus('SETTLED' as any), false);
    assert.equal(isPayableStatus('EXPIRED' as any), false);
    assert.equal(isPayableStatus('CANCELLED' as any), false);
  });

  it('detects max uses reached', () => {
    assert.equal(hasReachedMaxUses({ maxUses: null, useCount: 99 }), false);
    assert.equal(hasReachedMaxUses({ maxUses: 3, useCount: 2 }), false);
    assert.equal(hasReachedMaxUses({ maxUses: 3, useCount: 3 }), true);
    assert.equal(hasReachedMaxUses({ maxUses: 3, useCount: 4 }), true);
  });

  it('settles SINGLE links immediately', () => {
    assert.equal(
      nextStatusAfterPayment({ linkType: 'SINGLE' as any, maxUses: null, useCount: 0 }),
      'SETTLED',
    );
  });

  it('keeps MULTI links collecting until maxUses', () => {
    assert.equal(
      nextStatusAfterPayment({ linkType: 'MULTI' as any, maxUses: null, useCount: 5 }),
      'COLLECTING',
    );
    assert.equal(
      nextStatusAfterPayment({ linkType: 'MULTI' as any, maxUses: 3, useCount: 1 }),
      'COLLECTING',
    );
    assert.equal(
      nextStatusAfterPayment({ linkType: 'MULTI' as any, maxUses: 3, useCount: 2 }),
      'SETTLED',
    );
  });
});
