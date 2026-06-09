import assert from 'node:assert/strict';
import { describe, it, beforeEach } from 'node:test';
import { ReplyToSupportThreadUseCase } from '../src/application/use-cases/messages/reply-to-support-thread.use-case';
import { NotifySupportReplyUseCase } from '../src/application/use-cases/notifications/notify-support-reply.use-case';

type Row = Record<string, any>;
let seq = 0;

class OpsSupportPrismaFake {
  threads: Row[] = [];
  messages: Row[] = [];
  notifications: Row[] = [];

  supportThread = {
    findUnique: async ({ where }: { where: Row }) =>
      this.threads.find((t) => t.id === where.id) ?? null,
    update: async ({ where, data }: { where: Row; data: Row }) => {
      const t = this.threads.find((r) => r.id === where.id);
      if (!t) throw new Error('not found');
      Object.assign(t, data);
      return { ...t };
    },
  };

  supportMessage = {
    create: async ({ data }: { data: Row }) => {
      const row = { id: `sm_${++seq}`, createdAt: new Date(), ...data };
      this.messages.push(row);
      return { ...row };
    },
  };

  notification = {
    create: async ({ data }: { data: Row }) => {
      const row = { id: `n_${++seq}`, ...data };
      this.notifications.push(row);
      return { ...row };
    },
  };
}

const ctx = { adminUserId: 'admin1', adminEmail: 'admin@payspin.app' };

describe('ReplyToSupportThreadUseCase', () => {
  let db: OpsSupportPrismaFake;
  let audit: { calls: any[]; record: (...a: any[]) => Promise<void> };
  let notify: { calls: any[]; execute: (input: any) => Promise<void> };

  beforeEach(() => {
    db = new OpsSupportPrismaFake();
    audit = { calls: [], record: async (...a: any[]) => { audit.calls.push(a); } };
    notify = { calls: [], execute: async (input: any) => { notify.calls.push(input); } };
  });

  it('writes an OUT message, flags user-unread, clears admin-unread and notifies', async () => {
    db.threads.push({ id: 't1', userId: 'u1', unread: true, userUnread: false });
    const useCase = new ReplyToSupportThreadUseCase(db as any, audit as any, notify as any);

    const message = await useCase.execute('t1', { body: 'Looking into it now.' }, ctx as any);

    assert.equal(message.direction, 'OUT');
    assert.equal(db.threads[0].unread, false);
    assert.equal(db.threads[0].userUnread, true);
    assert.equal(audit.calls.length, 1);
    assert.equal(notify.calls.length, 1);
    assert.equal(notify.calls[0].userId, 'u1');
    assert.equal(notify.calls[0].threadId, 't1');
    assert.equal(notify.calls[0].messageId, message.id);
  });

  it('does not notify legacy threads with no userId', async () => {
    db.threads.push({ id: 't2', userId: null, unread: true, userUnread: false });
    const useCase = new ReplyToSupportThreadUseCase(db as any, audit as any, notify as any);
    await useCase.execute('t2', { body: 'hi' }, ctx as any);
    assert.equal(notify.calls.length, 0);
  });

  it('rejects an empty reply body', async () => {
    db.threads.push({ id: 't3', userId: 'u1', unread: true, userUnread: false });
    const useCase = new ReplyToSupportThreadUseCase(db as any, audit as any, notify as any);
    await assert.rejects(() => useCase.execute('t3', { body: '' }, ctx as any));
  });
});

describe('NotifySupportReplyUseCase', () => {
  it('persists an in-app notification row and enqueues an FCM push', async () => {
    const db = new OpsSupportPrismaFake();
    const added: any[] = [];
    const queue = { add: async (...a: any[]) => { added.push(a); } };
    const useCase = new NotifySupportReplyUseCase(db as any, queue as any);

    await useCase.execute({ userId: 'u1', threadId: 't1', messageId: 'm1', body: 'Resolved for you' });

    assert.equal(db.notifications.length, 1);
    assert.equal(db.notifications[0].type, 'support.reply');
    assert.equal(db.notifications[0].userId, 'u1');
    assert.equal(added.length, 1);
    const [name, job] = added[0];
    assert.equal(name, 'push');
    assert.equal(job.userId, 'u1');
    assert.equal(job.data.threadId, 't1');
    assert.equal(job.data.type, 'support.reply');
  });
});
