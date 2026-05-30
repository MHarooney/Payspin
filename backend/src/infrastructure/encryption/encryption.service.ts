import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createCipheriv, createDecipheriv, randomBytes } from 'crypto';

@Injectable()
export class EncryptionService {
  private readonly key: Buffer;

  constructor(private readonly config: ConfigService) {
    const hexKey = this.config.get<string>('IBAN_ENCRYPTION_KEY');
    if (!hexKey || hexKey.length !== 64) {
      throw new Error('IBAN_ENCRYPTION_KEY must be a 64-character hex string (32 bytes)');
    }
    this.key = Buffer.from(hexKey, 'hex');
  }

  encrypt(plaintext: string): { ciphertext: string; iv: string } {
    const iv = randomBytes(12);
    const cipher = createCipheriv('aes-256-gcm', this.key, iv);
    const encrypted = Buffer.concat([cipher.update(plaintext, 'utf8'), cipher.final()]);
    const tag = cipher.getAuthTag();
    const payload = Buffer.concat([encrypted, tag]);
    return {
      ciphertext: payload.toString('base64'),
      iv: iv.toString('base64'),
    };
  }

  decrypt(ciphertext: string, iv: string): string {
    const ivBuffer = Buffer.from(iv, 'base64');
    const payload = Buffer.from(ciphertext, 'base64');
    const tag = payload.subarray(payload.length - 16);
    const data = payload.subarray(0, payload.length - 16);
    const decipher = createDecipheriv('aes-256-gcm', this.key, ivBuffer);
    decipher.setAuthTag(tag);
    return Buffer.concat([decipher.update(data), decipher.final()]).toString('utf8');
  }
}
