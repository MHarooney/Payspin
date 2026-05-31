import { Injectable } from '@nestjs/common';
import { NotificationListResponse, NotificationSummary } from '@payspin/shared-types';
import { listNotificationsSchema } from '@payspin/validators';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';

interface NotificationRow {
  id: string;
  type: string;
  title: string;
  body: string;
  data: unknown;
  readAt: Date | null;
  createdAt: Date;
}

@Injectable()
export class ListNotificationsUseCase {
  constructor(private readonly prisma: PrismaService) {}

  async execute(
    userId: string,
    query: { cursor?: string; limit?: number },
  ): Promise<NotificationListResponse> {
    const { cursor, limit } = listNotificationsSchema.parse(query);

    const rows = (await this.prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: limit + 1,
      ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
    })) as NotificationRow[];

    const hasMore = rows.length > limit;
    const page = hasMore ? rows.slice(0, limit) : rows;

    const unreadCount = await this.prisma.notification.count({
      where: { userId, readAt: null },
    });

    return {
      items: page.map((r) => this.toSummary(r)),
      unreadCount,
      nextCursor: hasMore ? page[page.length - 1].id : null,
    };
  }

  private toSummary(row: NotificationRow): NotificationSummary {
    return {
      id: row.id,
      type: row.type,
      title: row.title,
      body: row.body,
      data: (row.data as Record<string, unknown> | null) ?? null,
      readAt: row.readAt?.toISOString() ?? null,
      createdAt: row.createdAt.toISOString(),
    };
  }
}
