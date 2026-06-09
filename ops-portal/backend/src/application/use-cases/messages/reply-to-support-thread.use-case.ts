import { Injectable, NotFoundException } from '@nestjs/common';
import { createSupportMessageSchema } from '@payspin/validators';
import { AuditAction } from '../../../domain/constants';
import { AuditContext } from '../../../infrastructure/audit/audit.service';
import { AuditService } from '../../../infrastructure/audit/audit.service';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { NotifySupportReplyUseCase } from '../notifications/notify-support-reply.use-case';

@Injectable()
export class ReplyToSupportThreadUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly notify: NotifySupportReplyUseCase,
  ) {}

  async execute(id: string, body: unknown, ctx: AuditContext) {
    const input = createSupportMessageSchema.parse(body);
    const thread = await this.prisma.supportThread.findUnique({ where: { id } });
    if (!thread) throw new NotFoundException('Thread not found');

    const message = await this.prisma.supportMessage.create({
      data: { threadId: id, direction: 'OUT', body: input.body, authorName: ctx.adminEmail },
    });
    // Admin reply: flag user-unread, clear admin-unread, bump activity.
    await this.prisma.supportThread.update({
      where: { id },
      data: { lastMessageAt: new Date(), unread: false, userUnread: true },
    });

    await this.audit.record(ctx, {
      action: AuditAction.SUPPORT_REPLY,
      targetType: 'support_thread',
      targetId: id,
    });

    // Only consumer-owned threads have a user to notify (legacy seed rows are null).
    if (thread.userId) {
      await this.notify.execute({
        userId: thread.userId,
        threadId: id,
        messageId: message.id,
        body: input.body,
      });
    }

    return message;
  }
}
