import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';

@Injectable()
export class MarkSupportThreadReadUseCase {
  constructor(private readonly prisma: PrismaService) {}

  /** Clears the admin-side unread flag on a thread. Idempotent. */
  async execute(id: string): Promise<{ success: true }> {
    await this.prisma.supportThread.updateMany({
      where: { id, unread: true },
      data: { unread: false },
    });
    return { success: true };
  }
}
