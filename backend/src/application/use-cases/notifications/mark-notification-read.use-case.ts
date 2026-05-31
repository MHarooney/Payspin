import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';

@Injectable()
export class MarkNotificationReadUseCase {
  constructor(private readonly prisma: PrismaService) {}

  /** Marks a single notification read. Scoped by userId so callers can't touch others' rows. */
  async execute(userId: string, notificationId: string): Promise<{ updated: number }> {
    const result = await this.prisma.notification.updateMany({
      where: { id: notificationId, userId, readAt: null },
      data: { readAt: new Date() },
    });
    return { updated: result.count };
  }

  async markAll(userId: string): Promise<{ updated: number }> {
    const result = await this.prisma.notification.updateMany({
      where: { userId, readAt: null },
      data: { readAt: new Date() },
    });
    return { updated: result.count };
  }
}
