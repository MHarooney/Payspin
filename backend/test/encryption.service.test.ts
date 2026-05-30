import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { EncryptionService } from '../src/infrastructure/encryption/encryption.service';

const KEY = 'a'.repeat(64); // 32 bytes hex
const config = { get: () => KEY } as any;

describe('EncryptionService', () => {
  it('rejects a key that is not 64 hex chars', () => {
    assert.throws(() => new EncryptionService({ get: () => 'short' } as any));
    assert.throws(() => new EncryptionService({ get: () => undefined } as any));
  });

  it('round-trips a value', () => {
    const svc = new EncryptionService(config);
    const { ciphertext, iv } = svc.encrypt('NL91ABNA0417164300');
    assert.notEqual(ciphertext, 'NL91ABNA0417164300');
    assert.equal(svc.decrypt(ciphertext, iv), 'NL91ABNA0417164300');
  });

  it('uses a fresh IV per encryption', () => {
    const svc = new EncryptionService(config);
    const a = svc.encrypt('same-value');
    const b = svc.encrypt('same-value');
    assert.notEqual(a.iv, b.iv);
    assert.notEqual(a.ciphertext, b.ciphertext);
  });

  it('fails to decrypt tampered ciphertext (auth tag check)', () => {
    const svc = new EncryptionService(config);
    const { ciphertext, iv } = svc.encrypt('NL91ABNA0417164300');
    const raw = Buffer.from(ciphertext, 'base64');
    raw[0] ^= 0xff;
    const tampered = raw.toString('base64');
    assert.throws(() => svc.decrypt(tampered, iv));
  });
});
