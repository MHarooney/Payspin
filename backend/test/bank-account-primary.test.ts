import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { GetDefaultBankAccountUseCase } from '../src/application/use-cases/payment-links/get-default-bank-account.use-case';
import { CreateBankAccountUseCase } from '../src/application/use-cases/bank-accounts/create-bank-account.use-case';
import { SetPrimaryBankAccountUseCase } from '../src/application/use-cases/bank-accounts/set-primary-bank-account.use-case';
import { DeleteBankAccountUseCase } from '../src/application/use-cases/bank-accounts/delete-bank-account.use-case';

type Row = Record<string, any>;
let seq = 0;

/**
 * Purpose-built in-memory double covering only the bank-account operations the
 * primary/default use-cases touch (incl. both array- and callback-style
 * $transaction).
 */
class BankPrismaFake {
  accounts: Row[] = [];
  links: Row[] = [];
  connections: Row[] = [];

  private filter(rows: Row[], where: Row = {}): Row[] {
    return rows.filter((r) =>
      Object.entries(where).every(([k, v]) => r[k] === v),
    );
  }

  private sort(rows: Row[], orderBy?: Row | Row[]): Row[] {
    if (!orderBy) return rows;
    const orders = Array.isArray(orderBy) ? orderBy : [orderBy];
    return [...rows].sort((a, b) => {
      for (const o of orders) {
        const [key, dir] = Object.entries(o)[0] as [string, 'asc' | 'desc'];
        const av = a[key];
        const bv = b[key];
        if (av === bv) continue;
        const cmp = av > bv ? 1 : -1;
        return dir === 'desc' ? -cmp : cmp;
      }
      return 0;
    });
  }

  bankAccount = {
    findFirst: async ({ where, orderBy }: { where?: Row; orderBy?: Row | Row[] }) =>
      this.sort(this.filter(this.accounts, where), orderBy)[0] ?? null,
    findMany: async ({ where, orderBy }: { where?: Row; orderBy?: Row | Row[] }) =>
      this.sort(this.filter(this.accounts, where), orderBy),
    count: async ({ where }: { where?: Row }) => this.filter(this.accounts, where).length,
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
    updateMany: async ({ where, data }: { where?: Row; data: Row }) => {
      const targets = this.filter(this.accounts, where);
      targets.forEach((r) => Object.assign(r, data));
      return { count: targets.length };
    },
    delete: async ({ where }: { where: Row }) => {
      this.accounts = this.accounts.filter((r) => r.id !== where.id);
      return {} as Row;
    },
  };

  paymentLink = {
    count: async ({ where }: { where?: Row }) => this.filter(this.links, where).length,
  };

  bankConnection = {
    updateMany: async ({ where, data }: { where?: Row; data: Row }) => {
      const targets = this.filter(this.connections, where);
      targets.forEach((r) => Object.assign(r, data));
      return { count: targets.length };
    },
  };

  async $transaction(arg: any): Promise<any> {
    return Array.isArray(arg) ? Promise.all(arg) : arg(this);
  }
}

const fakeEncryption = {
  encrypt: (plain: string) => ({ ciphertext: `ct:${plain}`, iv: 'iv' }),
  decrypt: (ciphertext: string, _iv: string) => ciphertext.replace(/^ct:/, ''),
} as any;

describe('GetDefaultBankAccountUseCase', () => {
  let db: BankPrismaFake;
  let useCase: GetDefaultBankAccountUseCase;

  beforeEach(() => {
    db = new BankPrismaFake();
    useCase = new GetDefaultBankAccountUseCase(db as any);
  });

  it('returns the primary account even when a newer non-primary exists', async () => {
    db.accounts.push({ id: 'old', userId: 'u1', isPrimary: true, createdAt: new Date(1) });
    db.accounts.push({ id: 'new', userId: 'u1', isPrimary: false, createdAt: new Date(2) });
    const result = await useCase.execute('u1');
    assert.equal(result.id, 'old');
  });

  it('falls back to the newest when none is flagged primary', async () => {
    db.accounts.push({ id: 'a', userId: 'u1', isPrimary: false, createdAt: new Date(1) });
    db.accounts.push({ id: 'b', userId: 'u1', isPrimary: false, createdAt: new Date(2) });
    const result = await useCase.execute('u1');
    assert.equal(result.id, 'b');
  });

  it('throws when the user has no accounts', async () => {
    await assert.rejects(() => useCase.execute('u1'), /Add a bank account/);
  });
});

describe('CreateBankAccountUseCase (auto-primary)', () => {
  let db: BankPrismaFake;
  let useCase: CreateBankAccountUseCase;

  beforeEach(() => {
    db = new BankPrismaFake();
    useCase = new CreateBankAccountUseCase(db as any, fakeEncryption);
  });

  it('marks the first account primary and later ones non-primary', async () => {
    const first = await useCase.execute('u1', { iban: 'NL91ABNA0417164300', accountHolder: 'Jane Doe' });
    assert.equal(first.isPrimary, true);
    const second = await useCase.execute('u1', { iban: 'NL02ABNA0123456789', accountHolder: 'Jane Doe' });
    assert.equal(second.isPrimary, false);
  });
});

describe('SetPrimaryBankAccountUseCase', () => {
  let db: BankPrismaFake;
  let useCase: SetPrimaryBankAccountUseCase;

  beforeEach(() => {
    db = new BankPrismaFake();
    useCase = new SetPrimaryBankAccountUseCase(db as any);
    db.accounts.push({ id: 'a', userId: 'u1', isPrimary: true, ibanLast4: '0001', accountHolder: 'A', bankName: null, verified: true, createdAt: new Date(1) });
    db.accounts.push({ id: 'b', userId: 'u1', isPrimary: false, ibanLast4: '0002', accountHolder: 'B', bankName: null, verified: true, createdAt: new Date(2) });
  });

  it('switches the primary and clears the previous one', async () => {
    const updated = await useCase.execute('u1', 'b');
    assert.equal(updated.isPrimary, true);
    assert.equal(db.accounts.find((a) => a.id === 'a')!.isPrimary, false);
    assert.equal(db.accounts.find((a) => a.id === 'b')!.isPrimary, true);
  });

  it('is idempotent when the account is already primary', async () => {
    const updated = await useCase.execute('u1', 'a');
    assert.equal(updated.isPrimary, true);
    assert.equal(db.accounts.filter((a) => a.isPrimary).length, 1);
  });

  it('rejects an account owned by another user', async () => {
    await assert.rejects(() => useCase.execute('intruder', 'a'), /not found/i);
  });
});

describe('DeleteBankAccountUseCase', () => {
  let db: BankPrismaFake;
  let useCase: DeleteBankAccountUseCase;

  beforeEach(() => {
    db = new BankPrismaFake();
    useCase = new DeleteBankAccountUseCase(db as any);
  });

  it('blocks deletion when the account is used by payment links', async () => {
    db.accounts.push({ id: 'a', userId: 'u1', isPrimary: true, createdAt: new Date(1) });
    db.links.push({ id: 'l1', bankAccountId: 'a' });
    await assert.rejects(() => useCase.execute('u1', 'a'), /existing payment links/);
    assert.equal(db.accounts.length, 1);
  });

  it('promotes the next account when the primary is removed', async () => {
    db.accounts.push({ id: 'a', userId: 'u1', isPrimary: true, createdAt: new Date(1) });
    db.accounts.push({ id: 'b', userId: 'u1', isPrimary: false, createdAt: new Date(2) });
    await useCase.execute('u1', 'a');
    assert.equal(db.accounts.length, 1);
    assert.equal(db.accounts[0].id, 'b');
    assert.equal(db.accounts[0].isPrimary, true);
  });

  it('detaches open-banking connections that pointed at the account', async () => {
    db.accounts.push({ id: 'a', userId: 'u1', isPrimary: false, createdAt: new Date(1) });
    db.connections.push({ id: 'c1', bankAccountId: 'a' });
    await useCase.execute('u1', 'a');
    assert.equal(db.connections[0].bankAccountId, null);
  });

  it('rejects an account owned by another user', async () => {
    db.accounts.push({ id: 'a', userId: 'u1', isPrimary: true, createdAt: new Date(1) });
    await assert.rejects(() => useCase.execute('intruder', 'a'), /not found/i);
  });
});
