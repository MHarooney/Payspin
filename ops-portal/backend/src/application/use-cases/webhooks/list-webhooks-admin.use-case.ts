import { Injectable } from '@nestjs/common';
import { AdminWebhookListItem, Paginated } from '@payspin/shared-types';
import { paginationSchema } from '@payspin/validators';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';

@Injectable()
export class ListWebhooksAdminUseCase {
  constructor(private readonly prisma: PrismaService) {}

  async execute(query: unknown): Promise<Paginated<AdminWebhookListItem>> {
    const { page, pageSize } = paginationSchema.parse(query);

    const [total, events] = await Promise.all([
      this.prisma.webhookEvent.count(),
      this.prisma.webhookEvent.findMany({
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
    ]);

    // Try to link each webhook to a payment via yapilyPaymentId in payload
    const items: AdminWebhookListItem[] = events.map((e) => {
      let linkedPaymentId: string | null = null;
      try {
        const p = e.payload as Record<string, unknown>;
        const yapilyId = (p?.['id'] ?? p?.['paymentId']) as string | undefined;
        if (yapilyId) linkedPaymentId = yapilyId;
      } catch { /* ignore */ }
      return {
        id: e.id,
        eventId: e.eventId,
        eventType: e.eventType,
        processedAt: e.processedAt?.toISOString() ?? null,
        linkedPaymentId,
        createdAt: e.createdAt.toISOString(),
      };
    });

    return { items, total, page, pageSize, totalPages: Math.ceil(total / pageSize) || 1 };
  }
}
