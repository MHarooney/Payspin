import { Injectable } from '@nestjs/common';
import { SupportThreadView } from '@payspin/shared-types';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { SupportMapper } from './support.mapper';

@Injectable()
export class ListUserSupportThreadsUseCase {
  constructor(private readonly prisma: PrismaService) {}

  async execute(userId: string): Promise<SupportThreadView[]> {
    const threads = await this.prisma.supportThread.findMany({
      where: { userId },
      orderBy: { lastMessageAt: 'desc' },
      include: { messages: { orderBy: { createdAt: 'desc' }, take: 1 } },
      take: 100,
    });
    return threads.map((t) => SupportMapper.toView(t, t.messages[0]?.body ?? ''));
  }
}
