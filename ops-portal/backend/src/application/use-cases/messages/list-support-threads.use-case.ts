import { Injectable } from '@nestjs/common';
import { SupportThreadDto } from '@payspin/shared-types';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';

export interface ListSupportThreadsFilter {
  status?: string;
  userId?: string;
}

@Injectable()
export class ListSupportThreadsUseCase {
  constructor(private readonly prisma: PrismaService) {}

  async execute(filter: ListSupportThreadsFilter = {}): Promise<SupportThreadDto[]> {
    const where: Prisma.SupportThreadWhereInput = {};
    if (filter.status) where.status = filter.status;
    if (filter.userId) where.userId = filter.userId;

    const threads = await this.prisma.supportThread.findMany({
      where,
      orderBy: { lastMessageAt: 'desc' },
      include: { messages: { orderBy: { createdAt: 'desc' }, take: 1 } },
      take: 100,
    });
    return threads.map((t) => ({
      id: t.id,
      userId: t.userId,
      userRef: t.userRef,
      subjectName: t.subjectName,
      category: t.category,
      contextRef: t.contextRef,
      meta: t.meta,
      status: t.status,
      unread: t.unread,
      userUnread: t.userUnread,
      preview: t.messages[0]?.body ?? '',
      lastMessageAt: t.lastMessageAt.toISOString(),
    }));
  }
}
