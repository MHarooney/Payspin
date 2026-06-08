import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { CompleteBankConnectionUseCase } from '../src/application/use-cases/open-banking/complete-bank-connection.use-case';

type Row = Record<string, any>;
let seq = 0;

class ConnectPrismaFake {
  accounts: Row[] = [];
  connections: Row[] = [];

  private filter(rows: Row[], where: Row = {}): Row[] {
    return rows.filter((r) =>
      Object.entries(where).every(([k, v]) => r[k] === v),
    );
  }

  bankAccount = {
    findMany: async ({ where }: { where?: Row }) => this.filter(this.accounts, where),
    create: async ({ data }: { data: Row }) => {
      const row: Row = { id: `ba_${++seq}`, createdAt: new Date(Date.now() + seq), ...data };
      this.accounts.push(row);
      return { ...row };
    },
    update: async ({ where, data }: { where: Row; data: Row }) => {
      const row = this.accounts.find((r) => r.id === where.id);
      if (!row) throw new Error('not found');
      Object.assign(row, data);
      return { ...row };
    },
  };

  bankConnection = {
    findFirst: async ({ where }: { where?: Row }) => this.filter(this.connections, where)[0] ?? null,
    update: async ({ where, data }: { where: Row; data: Row }) => {
      const row = this.connections.find((r) => r.id === where.id);
      if (!row) throw new Error('not found');
      Object.assign(row, data);
      return { ...row };
    },
  };

  async $transaction(arg: any): Promise<any> {
    return arg(this);
  }
}

const fakeEncryption = {
  encrypt: (plain: string) => ({ ciphertext: `ct:${plain}`, iv: 'iv' }),
  decrypt: (ciphertext: string, _iv: string) => ciphertext.replace(/^ct:/, ''),
} as any;

const luigiIban = 'DE89370400440532013000';

describe('CompleteBankConnectionUseCase (IBAN dedup)', () => {
  let db: ConnectPrismaFake;
  let useCase: CompleteBankConnectionUseCase;
  let aisGateway: { getAccounts: (token: string) => Promise<any[]> };

  beforeEach(() => {
    db = new ConnectPrismaFake();
    db.connections.push({
      id: 'conn-1',
      userId: 'u1',
      yapilyAuthId: 'yap-auth-1',
      institutionId: 'modelo-sandbox',
      status: 'PENDING',
    });
    db.accounts.push({
      id: 'existing',
      userId: 'u1',
      ibanEncrypted: `ct:${luigiIban}`,
      ibanIv: 'iv',
      ibanLast4: '3000',
      accountHolder: 'Luigi International',
      bankName: null,
      verified: false,
      isPrimary: true,
      verificationSource: 'MANUAL',
      createdAt: new Date(1),
    });

    aisGateway = {
      getAccounts: async () => [
        {
          accountNames: [{ name: 'Luigi International' }],
          institution: { name: 'Modelo Sandbox' },
          accountIdentifications: [{ type: 'IBAN', identification: luigiIban }],
        },
      ],
    };

    useCase = new CompleteBankConnectionUseCase(db as any, fakeEncryption, aisGateway as any);
  });

  it('reuses an existing IBAN instead of creating a duplicate row', async () => {
    const result = await useCase.execute('u1', {
      connectionId: 'yap-auth-1',
      consentToken: 'consent-token',
    });

    assert.equal(result.id, 'existing');
    assert.equal(result.verified, true);
    assert.equal(db.accounts.length, 1);
    assert.equal(db.connections[0].status, 'COMPLETED');
    assert.equal(db.connections[0].bankAccountId, 'existing');
    assert.equal(db.accounts[0].verificationSource, 'YAPILY');
    assert.equal(db.accounts[0].isPrimary, true);
  });

  it('creates a new account when the IBAN is new for the user', async () => {
    db.accounts = [];
    const result = await useCase.execute('u1', {
      connectionId: 'yap-auth-1',
      consentToken: 'consent-token',
    });

    assert.notEqual(result.id, 'existing');
    assert.equal(db.accounts.length, 1);
    assert.equal(result.isPrimary, true);
    assert.equal(result.verified, true);
  });
});
