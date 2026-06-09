import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { ForbiddenException, UnauthorizedException } from '@nestjs/common';
import { FakePrisma } from './helpers/fake-prisma';
import { ReauthenticatePhoneUseCase } from '../src/application/use-cases/auth/reauthenticate-phone.use-case';

class FakeFirebase {
  enabled = true;
  decoded: { phone_number?: string } | null = { phone_number: '+31612345678' };

  isEnabled() {
    return this.enabled;
  }

  async verifyIdToken(_idToken: string) {
    return this.decoded;
  }
}

describe('ReauthenticatePhoneUseCase', () => {
  it('returns reauthenticated when Firebase phone matches the account', async () => {
    const prisma = new FakePrisma();
    prisma.users.push({
      id: 'u1',
      email: 'user@example.com',
      phoneE164: '+31612345678',
      phoneVerifiedAt: new Date(),
    });
    const firebase = new FakeFirebase();
    const useCase = new ReauthenticatePhoneUseCase(prisma as any, firebase as any);

    const res = await useCase.execute('u1', { idToken: 'valid.token' });
    assert.deepEqual(res, { reauthenticated: true });
  });

  it('rejects when Firebase phone does not match', async () => {
    const prisma = new FakePrisma();
    prisma.users.push({
      id: 'u1',
      email: 'user@example.com',
      phoneE164: '+31612345678',
      phoneVerifiedAt: new Date(),
    });
    const firebase = new FakeFirebase();
    firebase.decoded = { phone_number: '+31687654321' };
    const useCase = new ReauthenticatePhoneUseCase(prisma as any, firebase as any);

    await assert.rejects(
      () => useCase.execute('u1', { idToken: 'valid.token' }),
      ForbiddenException,
    );
  });

  it('rejects when account has no verified phone', async () => {
    const prisma = new FakePrisma();
    prisma.users.push({
      id: 'u1',
      email: 'user@example.com',
      phoneE164: null,
      phoneVerifiedAt: null,
    });
    const firebase = new FakeFirebase();
    const useCase = new ReauthenticatePhoneUseCase(prisma as any, firebase as any);

    await assert.rejects(
      () => useCase.execute('u1', { idToken: 'valid.token' }),
      /No verified phone/,
    );
  });

  it('rejects invalid Firebase token', async () => {
    const prisma = new FakePrisma();
    prisma.users.push({
      id: 'u1',
      email: 'user@example.com',
      phoneE164: '+31612345678',
      phoneVerifiedAt: new Date(),
    });
    const firebase = new FakeFirebase();
    firebase.decoded = null;
    const useCase = new ReauthenticatePhoneUseCase(prisma as any, firebase as any);

    await assert.rejects(
      () => useCase.execute('u1', { idToken: 'invalid.token.here' }),
      UnauthorizedException,
    );
  });
});
