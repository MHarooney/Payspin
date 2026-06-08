import { Injectable } from '@nestjs/common';
import { SupportThreadDto } from '@payspin/shared-types';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';

@Injectable()
export class ListSupportThreadsUseCase {
  constructor(private readonly prisma: PrismaService) {}

  async execute(): Promise<SupportThreadDto[]> {
    const threads = await this.prisma.supportThread.findMany({
      orderBy: { lastMessageAt: 'desc' },
      include: { messages: { orderBy: { createdAt: 'desc' }, take: 1 } },
      take: 100,
    });
    return threads.map((t) => ({
      id: t.id,
      userRef: t.userRef,
      subjectName: t.subjectName,
      meta: t.meta,
      status: t.status,
      unread: t.unread,
      preview: t.messages[0]?.body ?? '',
      lastMessageAt: t.lastMessageAt.toISOString(),
    }));
  }
}
