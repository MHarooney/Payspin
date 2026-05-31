import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { ibanCountry } from '@payspin/validators';
import {
  institutionConfigFromEnv,
  resolveInstitutionForIban,
} from '../src/domain/utils/institution-routing';

describe('ibanCountry', () => {
  it('extracts NL from a Dutch IBAN', () => {
    assert.equal(ibanCountry('NL13ABNA0885334361'), 'NL');
  });

  it('extracts DE from a German IBAN', () => {
    assert.equal(ibanCountry('DE89370400440532013000'), 'DE');
  });

  it('normalizes spacing and case', () => {
    assert.equal(ibanCountry('de89 3704 0044 0532 0130 00'), 'DE');
  });

  it('returns null for an unknown country prefix', () => {
    assert.equal(ibanCountry('ZZ00000000000000'), null);
  });

  it('returns null when the prefix is not a 2-letter code', () => {
    assert.equal(ibanCountry('12345678'), null);
  });
});

describe('resolveInstitutionForIban', () => {
  const config = institutionConfigFromEnv((key) =>
    ({
      YAPILY_INSTITUTION_NL: 'nl-bank-sandbox',
      YAPILY_INSTITUTION_DE: 'de-bank-sandbox',
      YAPILY_DEFAULT_INSTITUTION: 'modelo-sandbox',
    })[key],
  );

  it('routes a NL IBAN to the NL institution', () => {
    const res = resolveInstitutionForIban('NL13ABNA0885334361', config);
    assert.equal(res.country, 'NL');
    assert.equal(res.institutionId, 'nl-bank-sandbox');
  });

  it('routes a DE IBAN to the DE institution', () => {
    const res = resolveInstitutionForIban('DE89370400440532013000', config);
    assert.equal(res.country, 'DE');
    assert.equal(res.institutionId, 'de-bank-sandbox');
  });

  it('falls back to the default for an unmapped country (GB)', () => {
    const res = resolveInstitutionForIban('GB82WEST12345698765432', config);
    assert.equal(res.country, 'GB');
    assert.equal(res.institutionId, 'modelo-sandbox');
  });

  it('falls back to the default when the IBAN is missing', () => {
    const res = resolveInstitutionForIban(null, config);
    assert.equal(res.country, null);
    assert.equal(res.institutionId, 'modelo-sandbox');
  });
});
