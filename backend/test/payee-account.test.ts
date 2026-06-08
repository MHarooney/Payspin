import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { resolvePayeeAccount } from '../src/domain/utils/payee-account';

describe('resolvePayeeAccount', () => {
  it('uses IBAN + payment currency for SEPA (NL) payees', () => {
    const res = resolvePayeeAccount('NL91ABNA0417164300', 'EUR');
    assert.deepEqual(res.identifications, [
      { type: 'IBAN', identification: 'NL91ABNA0417164300' },
    ]);
    assert.equal(res.currency, 'EUR');
  });

  it('uses IBAN for German (DE) payees', () => {
    const res = resolvePayeeAccount('DE89370400440532013000', 'EUR');
    assert.deepEqual(res.identifications, [
      { type: 'IBAN', identification: 'DE89370400440532013000' },
    ]);
    assert.equal(res.currency, 'EUR');
  });

  it('derives SORT_CODE + ACCOUNT_NUMBER (GBP) for UK payees', () => {
    // GB IBAN structure: GB kk BBBB SSSSSS AAAAAAAA
    const res = resolvePayeeAccount('GB29NWBK60161331926819', 'EUR');
    assert.deepEqual(res.identifications, [
      { type: 'SORT_CODE', identification: '601613' },
      { type: 'ACCOUNT_NUMBER', identification: '31926819' },
    ]);
    assert.equal(res.currency, 'GBP');
  });

  it('derives Faster Payments details from the Ozone modelo-sandbox IBAN', () => {
    // The exact case that Yapily rejected as an IBAN but accepted as sort/acct.
    const res = resolvePayeeAccount('GB29OZON10000109010103', 'EUR');
    assert.deepEqual(res.identifications, [
      { type: 'SORT_CODE', identification: '100001' },
      { type: 'ACCOUNT_NUMBER', identification: '09010103' },
    ]);
    assert.equal(res.currency, 'GBP');
  });

  it('normalizes spacing and case', () => {
    const res = resolvePayeeAccount('nl91 abna 0417 1643 00', 'EUR');
    assert.deepEqual(res.identifications, [
      { type: 'IBAN', identification: 'NL91ABNA0417164300' },
    ]);
  });
});
