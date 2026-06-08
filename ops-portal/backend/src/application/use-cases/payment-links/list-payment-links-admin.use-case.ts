import { Injectable } from '@nestjs/common';
import { AdminPaymentLinkListItem, Paginated } from '@payspin/shared-types';
import { paginationSchema } from '@payspin/validators';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';

@Injectable()
export class ListPaymentLinksAdminUseCase {
  constructor(private readonly prisma: PrismaService) {}

  async execute(query: unknown): Promise<Paginated<AdminPaymentLinkListItem>> {
    const { page, pageSize } = paginationSchema.parse(query);

    const [total, links] = await Promise.all([
      this.prisma.paymentLink.count(),
      this.prisma.paymentLink.findMany({
        include: { payeeUser: { select: { displayName: true, email: true } } },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
    ]);

    const items: AdminPaymentLinkListItem[] = links.map((l) => ({
      id: l.id,
      shortCode: l.shortCode,
      payeeName: l.payeeUser.displayName ?? l.payeeUser.email,
      payeeUserId: l.payeeUserId,
      amountCents: l.amountCents,
      currency: l.currency,
      description: l.description,
      status: l.status,
      linkType: l.linkType,
      useCount: l.useCount,
      maxUses: l.maxUses,
      expiresAt: l.expiresAt?.toISOString() ?? null,
      createdAt: l.createdAt.toISOString(),
    }));

    return { items, total, page, pageSize, totalPages: Math.ceil(total / pageSize) || 1 };
  }
}
