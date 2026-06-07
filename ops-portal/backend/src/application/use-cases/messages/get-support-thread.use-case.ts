import { Injectable, NotFoundException } from '@nestjs/common';
import { SupportThreadDetail } from '@payspin/shared-types';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';

@Injectable()
export class GetSupportThreadUseCase {
  constructor(private readonly prisma: PrismaService) {}

  async execute(id: string): Promise<SupportThreadDetail> {
    const thread = await this.prisma.supportThread.findUnique({
      where: { id },
      include: { messages: { orderBy: { createdAt: 'asc' } } },
    });
    if (!thread) {
      throw new NotFoundException('Thread not found');
    }
    return {
      id: thread.id,
      userRef: thread.userRef,
      subjectName: thread.subjectName,
      meta: thread.meta,
      status: thread.status,
      unread: thread.unread,
      preview: thread.messages[thread.messages.length - 1]?.body ?? '',
      lastMessageAt: thread.lastMessageAt.toISOString(),
      messages: thread.messages.map((m) => ({
        id: m.id,
        direction: m.direction as 'IN' | 'OUT',
        body: m.body,
        authorName: m.authorName,
        createdAt: m.createdAt.toISOString(),
      })),
    };
  }
}
