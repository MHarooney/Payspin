import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import {
  completeBankConnectionSchema,
  completePaymentSchema,
  createBankAccountSchema,
  createPaymentLinkSchema,
  initiatePaymentSchema,
  listInstitutionsSchema,
  registerSchema,
  validateIban,
} from '../src/index';

describe('validateIban', () => {
  it('accepts a valid NL IBAN (with spaces / lowercase)', () => {
    assert.equal(validateIban('nl91 abna 0417 1643 00'), null);
  });

  it('rejects an unknown country code', () => {
    assert.equal(validateIban('ZZ00 0000 0000'), 'Unknown IBAN country code');
  });

  it('rejects a wrong length for the country', () => {
    assert.equal(validateIban('NL91ABNA04171643'), 'Invalid IBAN length for NL');
  });

  it('rejects a bad checksum', () => {
    assert.equal(validateIban('NL00ABNA0417164300'), 'Invalid IBAN checksum');
  });
});

describe('createBankAccountSchema', () => {
  it('normalizes and accepts a valid IBAN', () => {
    const parsed = createBankAccountSchema.parse({
      iban: 'nl91 abna 0417 1643 00',
      accountHolder: 'Jane Doe',
    });
    assert.equal(parsed.iban, 'NL91ABNA0417164300');
  });

  it('rejects an invalid IBAN', () => {
    assert.throws(() =>
      createBankAccountSchema.parse({ iban: 'NL00ABNA0417164300', accountHolder: 'Jane' }),
    );
  });
});

describe('createPaymentLinkSchema', () => {
  it('defaults currency and linkType', () => {
    const parsed = createPaymentLinkSchema.parse({ amountCents: 2500 });
    assert.equal(parsed.currency, 'EUR');
    assert.equal(parsed.linkType, 'SINGLE');
  });

  it('rejects zero / negative / non-integer amounts', () => {
    assert.throws(() => createPaymentLinkSchema.parse({ amountCents: 0 }));
    assert.throws(() => createPaymentLinkSchema.parse({ amountCents: -1 }));
    assert.throws(() => createPaymentLinkSchema.parse({ amountCents: 10.5 }));
  });

  it('rejects amounts above the max', () => {
    assert.throws(() => createPaymentLinkSchema.parse({ amountCents: 1_000_000_000 }));
  });
});

describe('payer payment schemas', () => {
  it('initiate allows an optional positive integer amount', () => {
    assert.deepEqual(initiatePaymentSchema.parse({}), {});
    assert.equal(initiatePaymentSchema.parse({ amountCents: 500 }).amountCents, 500);
    assert.throws(() => initiatePaymentSchema.parse({ amountCents: -5 }));
    assert.throws(() => initiatePaymentSchema.parse({ amountCents: 1.5 }));
  });

  it('complete requires a paymentId', () => {
    assert.throws(() => completePaymentSchema.parse({}));
    assert.equal(
      completePaymentSchema.parse({ paymentId: 'pay-1' }).paymentId,
      'pay-1',
    );
  });
});

describe('open-banking schemas', () => {
  it('complete-connection requires connectionId + consentToken', () => {
    assert.throws(() => completeBankConnectionSchema.parse({ connectionId: 'c1' }));
    assert.ok(
      completeBankConnectionSchema.parse({ connectionId: 'c1', consentToken: 't1' }),
    );
  });

  it('institutions country must be a 2-letter code', () => {
    assert.ok(listInstitutionsSchema.parse({}));
    assert.equal(listInstitutionsSchema.parse({ country: 'NL' }).country, 'NL');
    assert.throws(() => listInstitutionsSchema.parse({ country: 'NLD' }));
    assert.throws(() => listInstitutionsSchema.parse({ country: '12' }));
  });
});

describe('registerSchema', () => {
  it('requires a valid email and 8+ char password', () => {
    assert.throws(() => registerSchema.parse({ email: 'x', password: 'longenough' }));
    assert.throws(() => registerSchema.parse({ email: 'a@b.co', password: 'short' }));
    assert.ok(registerSchema.parse({ email: 'a@b.co', password: 'longenough' }));
  });
});
