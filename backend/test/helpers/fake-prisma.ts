/**
 * Minimal in-memory Prisma double for use-case unit tests.
 * Implements only the subset of operations the payment/webhook flows use.
 */
import { Prisma } from '@prisma/client';

type Dict = Record<string, unknown>;

let idSeq = 0;
const nextId = (prefix: string) => `${prefix}_${++idSeq}`;

interface WhereClause {
  id?: string;
  email?: string;
  shortCode?: string;
  eventId?: string;
  paymentLinkId?: string;
  yapilyPaymentId?: string;
  status?: string | { in?: string[] };
  OR?: WhereClause[];
}

function statusMatches(actual: string, expected?: WhereClause['status']): boolean {
  if (expected === undefined) return true;
  if (typeof expected === 'string') return actual === expected;
  if (expected.in) return expected.in.includes(actual);
  return true;
}

function matches(row: Dict, where?: WhereClause): boolean {
  if (!where) return true;
  if (where.OR) {
    return where.OR.some((sub) => matches(row, sub));
  }
  if (where.id !== undefined && row.id !== where.id) return false;
  if (where.email !== undefined && row.email !== where.email) return false;
  if (where.shortCode !== undefined && row.shortCode !== where.shortCode) return false;
  if (where.eventId !== undefined && row.eventId !== where.eventId) return false;
  if (where.paymentLinkId !== undefined && row.paymentLinkId !== where.paymentLinkId) {
    return false;
  }
  if (
    where.yapilyPaymentId !== undefined &&
    row.yapilyPaymentId !== where.yapilyPaymentId
  ) {
    return false;
  }
  if (!statusMatches(row.status as string, where.status)) return false;
  return true;
}

function applyData(row: Dict, data: Dict): void {
  for (const [key, value] of Object.entries(data)) {
    if (value && typeof value === 'object' && 'increment' in (value as Dict)) {
      row[key] = ((row[key] as number) ?? 0) + ((value as Dict).increment as number);
    } else {
      row[key] = value;
    }
  }
}

export class FakePrisma {
  users: Dict[] = [];
  paymentLinks: Dict[] = [];
  payments: Dict[] = [];
  webhookEvents: Dict[] = [];

  /** Set to true to simulate a unique-constraint race on user.create. */
  failUserCreateWithP2002 = false;

  userAdminStates: Dict[] = [];

  userAdminState = {
    findUnique: async ({ where }: { where: { userId?: string } }) =>
      this.userAdminStates.find((s) => s.userId === where.userId) ?? null,
  };

  user = {
    findUnique: async ({ where }: { where: WhereClause }) =>
      this.users.find((u) => matches(u, where)) ?? null,
    create: async ({ data }: { data: Dict }) => {
      if (
        this.failUserCreateWithP2002 ||
        this.users.some((u) => u.email === data.email)
      ) {
        throw new Prisma.PrismaClientKnownRequestError('Unique constraint failed', {
          code: 'P2002',
          clientVersion: 'test',
        });
      }
      const row: Dict = {
        id: nextId('user'),
        displayName: null,
        createdAt: new Date(),
        ...data,
      };
      this.users.push(row);
      return { ...row };
    },
    update: async ({ where, data }: { where: WhereClause; data: Dict }) => {
      const u = this.users.find((row) => matches(row, where));
      if (!u) throw new Error('user not found');
      applyData(u, data);
      return { ...u };
    },
  };

  private hydrate(link: Dict | undefined, include?: Dict): Dict | undefined {
    if (!link) return undefined;
    if (!include) return { ...link };
    const out = { ...link };
    if (include.payeeUser) out.payeeUser = link.__payeeUser ?? { displayName: null, email: 'x@y.z' };
    if (include.bankAccount) out.bankAccount = link.__bankAccount ?? { accountHolder: 'Holder' };
    return out;
  }

  paymentLink = {
    findUnique: async ({ where, include }: { where: WhereClause; include?: Dict }) =>
      this.hydrate(
        this.paymentLinks.find((l) => matches(l, where)),
        include,
      ) ?? null,
    update: async ({
      where,
      data,
      include,
    }: {
      where: WhereClause;
      data: Dict;
      include?: Dict;
    }) => {
      const link = this.paymentLinks.find((l) => matches(l, where));
      if (!link) throw new Error('paymentLink not found');
      applyData(link, data);
      return this.hydrate(link, include);
    },
  };

  payment = {
    findFirst: async ({ where, include }: { where: WhereClause; include?: Dict }) => {
      const found = this.payments.find((p) => matches(p, where));
      if (!found) return null;
      const row = { ...found };
      if (include?.paymentLink) {
        row.paymentLink = this.paymentLinks.find((l) => l.id === found.paymentLinkId);
      }
      return row;
    },
    count: async ({ where }: { where?: WhereClause }) =>
      this.payments.filter((row) => matches(row, where)).length,
    findUniqueOrThrow: async ({ where }: { where: WhereClause }) => {
      const p = this.payments.find((row) => matches(row, where));
      if (!p) throw new Error('payment not found');
      return { ...p };
    },
    create: async ({ data }: { data: Dict }) => {
      const row: Dict = { id: nextId('pay'), yapilyPaymentId: null, completedAt: null, ...data };
      this.payments.push(row);
      return { ...row };
    },
    update: async ({ where, data }: { where: WhereClause; data: Dict }) => {
      const p = this.payments.find((row) => matches(row, where));
      if (!p) throw new Error('payment not found');
      applyData(p, data);
      return { ...p };
    },
    updateMany: async ({ where, data }: { where: WhereClause; data: Dict }) => {
      const targets = this.payments.filter((row) => matches(row, where));
      targets.forEach((row) => applyData(row, data));
      return { count: targets.length };
    },
  };

  webhookEvent = {
    create: async ({ data }: { data: Dict }) => {
      if (this.webhookEvents.some((e) => e.eventId === data.eventId)) {
        throw new Error('duplicate eventId');
      }
      const row: Dict = { id: nextId('evt'), processedAt: null, ...data };
      this.webhookEvents.push(row);
      return { ...row };
    },
    update: async ({ where, data }: { where: WhereClause; data: Dict }) => {
      const e = this.webhookEvents.find((row) => matches(row, where));
      if (!e) throw new Error('webhookEvent not found');
      applyData(e, data);
      return { ...e };
    },
  };

  async $transaction<T>(fn: (tx: FakePrisma) => Promise<T>): Promise<T> {
    return fn(this);
  }

  /** No-op stand-in for the `SELECT ... FOR UPDATE` row lock. */
  async $queryRaw(..._args: unknown[]): Promise<unknown[]> {
    return [];
  }

  // --- test seeding helpers ---
  seedLink(overrides: Dict = {}): Dict {
    const link: Dict = {
      id: nextId('link'),
      shortCode: nextId('code'),
      payeeUserId: 'payee-1',
      bankAccountId: 'bank-1',
      amountCents: 2500,
      currency: 'EUR',
      description: 'Test link',
      status: 'ACTIVE',
      linkType: 'SINGLE',
      maxUses: null,
      useCount: 0,
      expiresAt: null,
      __payeeUser: { displayName: 'Payee', email: 'payee@x.z' },
      __bankAccount: { accountHolder: 'Payee Holder' },
      ...overrides,
    };
    this.paymentLinks.push(link);
    return link;
  }
}
