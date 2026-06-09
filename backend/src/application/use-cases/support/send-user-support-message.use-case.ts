import { Injectable, NotFoundException } from '@nestjs/common';
import { SupportThreadWithMessages } from '@payspin/shared-types';
import { sendSupportMessageSchema } from '@payspin/validators';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { SupportMapper } from './support.mapper';

@Injectable()
export class SendUserSupportMessageUseCase {
  constructor(private readonly prisma: PrismaService) {}

  async execute(userId: string, id: string, body: unknown): Promise<SupportThreadWithMessages> {
    const input = sendSupportMessageSchema.parse(body);
    const thread = await this.prisma.supportThread.findFirst({ where: { id, userId } });
    if (!thread) throw new NotFoundException('Thread not found');

    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    const authorName = user ? SupportMapper.authorName(user) : 'You';

    await this.prisma.supportMessage.create({
      data: { threadId: id, direction: 'IN', authorName, body: input.body },
    });
    // A new user message flags admin-unread and reopens a RESOLVED thread.
    await this.prisma.supportThread.update({
      where: { id },
      data: { unread: true, status: 'OPEN', lastMessageAt: new Date() },
    });

    const updated = await this.prisma.supportThread.findUniqueOrThrow({
      where: { id },
      include: { messages: { orderBy: { createdAt: 'asc' } } },
    });
    return SupportMapper.toDetail(updated);
  }
}
