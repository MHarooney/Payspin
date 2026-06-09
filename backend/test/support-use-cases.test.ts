import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { CreateSupportThreadUseCase } from '../src/application/use-cases/support/create-support-thread.use-case';
import { GetUserSupportThreadUseCase } from '../src/application/use-cases/support/get-user-support-thread.use-case';
import { SendUserSupportMessageUseCase } from '../src/application/use-cases/support/send-user-support-message.use-case';
import { MarkSupportThreadReadUseCase } from '../src/application/use-cases/support/mark-support-thread-read.use-case';
import { GetSupportUnreadCountUseCase } from '../src/application/use-cases/support/get-support-unread-count.use-case';
import { ListUserSupportThreadsUseCase } from '../src/application/use-cases/support/list-user-support-threads.use-case';

type Row = Record<string, any>;
let seq = 0;

/** In-memory Prisma double covering the support_threads / support_messages /
 * users surface the consumer support use-cases touch. */
class SupportPrismaFake {
  threads: Row[] = [];
  messages: Row[] = [];
  users: Row[] = [];

  private filter(rows: Row[], where: Row = {}): Row[] {
    return rows.filter((r) => Object.entries(where).every(([k, v]) => r[k] === v));
  }

  private withMessages(t: Row): Row {
    const messages = this.messages
      .filter((m) => m.threadId === t.id)
      .sort((a, b) => a.createdAt.getTime() - b.createdAt.getTime());
    return { ...t, messages };
  }

  user = {
    findUnique: async ({ where }: { where: Row }) =>
      this.users.find((u) => u.id === where.id) ?? null,
  };

  supportThread = {
    create: async ({ data }: { data: Row }) => {
      const { messages, ...rest } = data;
      const thread: Row = {
        id: `st_${++seq}`,
        createdAt: new Date(Date.now() + seq),
        ...rest,
      };
      this.threads.push(thread);
      for (const m of messages?.create ?? []) {
        this.messages.push({
          id: `sm_${++seq}`,
          threadId: thread.id,
          createdAt: new Date(Date.now() + seq),
          ...m,
        });
      }
      return this.withMessages(thread);
    },
    findFirst: async ({ where }: { where: Row }) => {
      const t = this.filter(this.threads, where)[0];
      return t ? this.withMessages(t) : null;
    },
    findUniqueOrThrow: async ({ where }: { where: Row }) => {
      const t = this.threads.find((r) => r.id === where.id);
      if (!t) throw new Error('not found');
      return this.withMessages(t);
    },
    findMany: async ({ where }: { where?: Row }) =>
      this.filter(this.threads, where)
        .map((t) => this.withMessages(t))
        .sort((a, b) => b.lastMessageAt.getTime() - a.lastMessageAt.getTime()),
    update: async ({ where, data }: { where: Row; data: Row }) => {
      const t = this.threads.find((r) => r.id === where.id);
      if (!t) throw new Error('not found');
      Object.assign(t, data);
      return { ...t };
    },
    count: async ({ where }: { where?: Row }) => this.filter(this.threads, where).length,
  };

  supportMessage = {
    create: async ({ data }: { data: Row }) => {
      const row: Row = { id: `sm_${++seq}`, createdAt: new Date(Date.now() + seq), ...data };
      this.messages.push(row);
      return { ...row };
    },
  };
}

describe('CreateSupportThreadUseCase', () => {
  let db: SupportPrismaFake;
  let useCase: CreateSupportThreadUseCase;

  beforeEach(() => {
    db = new SupportPrismaFake();
    db.users.push({ id: 'u1', email: 'karim@payspin.app', displayName: 'Karim', phoneE164: null });
    useCase = new CreateSupportThreadUseCase(db as any);
  });

  it('creates a thread owned by the user with a first IN message and admin unread', async () => {
    const thread = await useCase.execute('u1', { category: 'PAYMENT', body: 'My payment is stuck' });
    assert.equal(db.threads.length, 1);
    assert.equal(db.threads[0].userId, 'u1');
    assert.equal(db.threads[0].unread, true);
    assert.equal(db.threads[0].userUnread, false);
    assert.equal(db.threads[0].status, 'OPEN');
    assert.equal(thread.subject, 'Payment issue');
    assert.equal(thread.messages.length, 1);
    assert.equal(thread.messages[0].direction, 'IN');
    assert.equal(thread.messages[0].body, 'My payment is stuck');
  });

  it('rejects an empty body', async () => {
    await assert.rejects(() => useCase.execute('u1', { body: '' }));
  });

  it('rejects a body over 4000 chars', async () => {
    await assert.rejects(() => useCase.execute('u1', { body: 'a'.repeat(4001) }));
  });
});

describe('GetUserSupportThreadUseCase (ownership)', () => {
  let db: SupportPrismaFake;
  let useCase: GetUserSupportThreadUseCase;

  beforeEach(() => {
    db = new SupportPrismaFake();
    db.threads.push({
      id: 'st_owned',
      userId: 'u1',
      subjectName: 'Help',
      category: null,
      contextRef: null,
      status: 'OPEN',
      userUnread: false,
      lastMessageAt: new Date(),
      createdAt: new Date(),
    });
    useCase = new GetUserSupportThreadUseCase(db as any);
  });

  it('returns the thread for its owner', async () => {
    const t = await useCase.execute('u1', 'st_owned');
    assert.equal(t.id, 'st_owned');
  });

  it('404s when another user requests it', async () => {
    await assert.rejects(() => useCase.execute('intruder', 'st_owned'), /not found/i);
  });
});

describe('SendUserSupportMessageUseCase (reopen)', () => {
  let db: SupportPrismaFake;
  let useCase: SendUserSupportMessageUseCase;

  beforeEach(() => {
    db = new SupportPrismaFake();
    db.users.push({ id: 'u1', email: 'karim@payspin.app', displayName: 'Karim', phoneE164: null });
    db.threads.push({
      id: 'st1',
      userId: 'u1',
      subjectName: 'Help',
      category: null,
      contextRef: null,
      status: 'RESOLVED',
      unread: false,
      userUnread: false,
      lastMessageAt: new Date(1),
      createdAt: new Date(1),
    });
    useCase = new SendUserSupportMessageUseCase(db as any);
  });

  it('appends an IN message, reopens a RESOLVED thread and flags admin unread', async () => {
    const updated = await useCase.execute('u1', 'st1', { body: 'still broken' });
    assert.equal(db.threads[0].status, 'OPEN');
    assert.equal(db.threads[0].unread, true);
    assert.equal(updated.messages.at(-1)?.body, 'still broken');
    assert.equal(updated.messages.at(-1)?.direction, 'IN');
  });

  it('404s for a non-owner', async () => {
    await assert.rejects(() => useCase.execute('intruder', 'st1', { body: 'hi' }), /not found/i);
  });
});

describe('MarkSupportThreadReadUseCase (idempotent)', () => {
  let db: SupportPrismaFake;
  let useCase: MarkSupportThreadReadUseCase;

  beforeEach(() => {
    db = new SupportPrismaFake();
    db.threads.push({ id: 'st1', userId: 'u1', userUnread: true, lastMessageAt: new Date() });
    useCase = new MarkSupportThreadReadUseCase(db as any);
  });

  it('clears userUnread and stays idempotent', async () => {
    const first = await useCase.execute('u1', 'st1');
    assert.equal(first.success, true);
    assert.equal(db.threads[0].userUnread, false);
    const second = await useCase.execute('u1', 'st1');
    assert.equal(second.success, true);
    assert.equal(db.threads[0].userUnread, false);
  });

  it('404s for a non-owner', async () => {
    await assert.rejects(() => useCase.execute('intruder', 'st1'), /not found/i);
  });
});

describe('GetSupportUnreadCountUseCase', () => {
  it('counts only the user\'s unread threads', async () => {
    const db = new SupportPrismaFake();
    db.threads.push({ id: 'a', userId: 'u1', userUnread: true });
    db.threads.push({ id: 'b', userId: 'u1', userUnread: false });
    db.threads.push({ id: 'c', userId: 'u2', userUnread: true });
    const useCase = new GetSupportUnreadCountUseCase(db as any);
    const result = await useCase.execute('u1');
    assert.equal(result.count, 1);
  });
});

describe('ListUserSupportThreadsUseCase', () => {
  it('returns only the user\'s threads, newest first', async () => {
    const db = new SupportPrismaFake();
    db.threads.push({ id: 'a', userId: 'u1', subjectName: 'A', category: null, contextRef: null, status: 'OPEN', userUnread: false, lastMessageAt: new Date(1), createdAt: new Date(1) });
    db.threads.push({ id: 'b', userId: 'u1', subjectName: 'B', category: null, contextRef: null, status: 'OPEN', userUnread: false, lastMessageAt: new Date(2), createdAt: new Date(2) });
    db.threads.push({ id: 'c', userId: 'u2', subjectName: 'C', category: null, contextRef: null, status: 'OPEN', userUnread: false, lastMessageAt: new Date(3), createdAt: new Date(3) });
    const useCase = new ListUserSupportThreadsUseCase(db as any);
    const result = await useCase.execute('u1');
    assert.equal(result.length, 2);
    assert.equal(result[0].id, 'b');
    assert.equal(result[1].id, 'a');
  });
});
