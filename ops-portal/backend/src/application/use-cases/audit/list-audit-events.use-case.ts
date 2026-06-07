import { Injectable } from '@nestjs/common';
import { AuditEventDto, Paginated } from '@payspin/shared-types';
import { paginationSchema } from '@payspin/validators';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';

@Injectable()
export class ListAuditEventsUseCase {
  constructor(private readonly prisma: PrismaService) {}

  async execute(query: unknown): Promise<Paginated<AuditEventDto>> {
    const { page, pageSize } = paginationSchema.parse(query);

    const [total, rows] = await Promise.all([
      this.prisma.adminAuditEvent.count(),
      this.prisma.adminAuditEvent.findMany({
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
    ]);

    return {
      items: rows.map((r) => ({
        id: r.id,
        adminEmail: r.adminEmail,
        action: r.action,
        targetType: r.targetType,
        targetId: r.targetId,
        before: r.before ?? null,
        after: r.after ?? null,
        ip: r.ip,
        createdAt: r.createdAt.toISOString(),
      })),
      total,
      page,
      pageSize,
      totalPages: Math.max(1, Math.ceil(total / pageSize)),
    };
  }
}
