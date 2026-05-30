import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import * as bcrypt from 'bcrypt';
import { FakePrisma } from './helpers/fake-prisma';
import { RegisterUserUseCase } from '../src/application/use-cases/auth/register-user.use-case';
import { LoginUserUseCase } from '../src/application/use-cases/auth/login-user.use-case';

const jwt = { sign: () => 'signed.jwt.token' } as any;

describe('RegisterUserUseCase', () => {
  it('registers a new user and returns a token', async () => {
    const prisma = new FakePrisma();
    const useCase = new RegisterUserUseCase(prisma as any, jwt);
    const res = await useCase.execute({
      email: 'New@Example.com',
      password: 'supersecret',
    });
    assert.equal(res.accessToken, 'signed.jwt.token');
    assert.equal(res.user.email, 'new@example.com');
    assert.equal(prisma.users.length, 1);
  });

  it('rejects invalid input', async () => {
    const prisma = new FakePrisma();
    const useCase = new RegisterUserUseCase(prisma as any, jwt);
    await assert.rejects(() => useCase.execute({ email: 'bad', password: '123' }));
  });

  it('rejects duplicate email via pre-check', async () => {
    const prisma = new FakePrisma();
    prisma.users.push({ id: 'u1', email: 'taken@example.com' });
    const useCase = new RegisterUserUseCase(prisma as any, jwt);
    await assert.rejects(
      () => useCase.execute({ email: 'taken@example.com', password: 'supersecret' }),
      /already registered/,
    );
  });

  it('maps a P2002 race to a 409 conflict', async () => {
    const prisma = new FakePrisma();
    prisma.failUserCreateWithP2002 = true;
    const useCase = new RegisterUserUseCase(prisma as any, jwt);
    await assert.rejects(
      () => useCase.execute({ email: 'race@example.com', password: 'supersecret' }),
      /already registered/,
    );
  });
});

describe('LoginUserUseCase', () => {
  async function seedUser(prisma: FakePrisma) {
    prisma.users.push({
      id: 'u1',
      email: 'user@example.com',
      passwordHash: await bcrypt.hash('correct-password', 4),
      displayName: null,
      createdAt: new Date(),
    });
  }

  it('logs in with valid credentials', async () => {
    const prisma = new FakePrisma();
    await seedUser(prisma);
    const useCase = new LoginUserUseCase(prisma as any, jwt);
    const res = await useCase.execute({
      email: 'User@Example.com',
      password: 'correct-password',
    });
    assert.equal(res.accessToken, 'signed.jwt.token');
  });

  it('rejects a wrong password with a generic message', async () => {
    const prisma = new FakePrisma();
    await seedUser(prisma);
    const useCase = new LoginUserUseCase(prisma as any, jwt);
    await assert.rejects(
      () => useCase.execute({ email: 'user@example.com', password: 'wrong' }),
      /Invalid email or password/,
    );
  });

  it('rejects an unknown user with the same generic message', async () => {
    const prisma = new FakePrisma();
    const useCase = new LoginUserUseCase(prisma as any, jwt);
    await assert.rejects(
      () => useCase.execute({ email: 'nobody@example.com', password: 'whatever' }),
      /Invalid email or password/,
    );
  });
});
