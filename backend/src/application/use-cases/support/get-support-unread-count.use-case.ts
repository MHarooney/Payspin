import { Injectable } from '@nestjs/common';
import { SupportUnreadCount } from '@payspin/shared-types';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';

@Injectable()
export class GetSupportUnreadCountUseCase {
  constructor(private readonly prisma: PrismaService) {}

  async execute(userId: string): Promise<SupportUnreadCount> {
    const count = await this.prisma.supportThread.count({
      where: { userId, userUnread: true },
    });
    return { count };
  }
}
