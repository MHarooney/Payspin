import { Injectable, NotFoundException } from '@nestjs/common';
import { SupportThreadWithMessages } from '@payspin/shared-types';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { SupportMapper } from './support.mapper';

@Injectable()
export class GetUserSupportThreadUseCase {
  constructor(private readonly prisma: PrismaService) {}

  async execute(userId: string, id: string): Promise<SupportThreadWithMessages> {
    // Filtering on userId means a wrong/foreign id returns null → 404, which
    // also avoids leaking whether the thread exists for another user.
    const thread = await this.prisma.supportThread.findFirst({
      where: { id, userId },
      include: { messages: { orderBy: { createdAt: 'asc' } } },
    });
    if (!thread) throw new NotFoundException('Thread not found');
    return SupportMapper.toDetail(thread);
  }
}
