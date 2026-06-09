import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';

@Injectable()
export class MarkSupportThreadReadUseCase {
  constructor(private readonly prisma: PrismaService) {}

  /** Clears the user-side unread flag. Idempotent. */
  async execute(userId: string, id: string): Promise<{ success: true }> {
    const thread = await this.prisma.supportThread.findFirst({ where: { id, userId } });
    if (!thread) throw new NotFoundException('Thread not found');
    if (thread.userUnread) {
      await this.prisma.supportThread.update({ where: { id }, data: { userUnread: false } });
    }
    return { success: true };
  }
}
