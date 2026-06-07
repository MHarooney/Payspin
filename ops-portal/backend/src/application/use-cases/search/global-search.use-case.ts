import { Injectable } from '@nestjs/common';
import { GlobalSearchResult } from '@payspin/shared-types';
import { globalSearchSchema } from '@payspin/validators';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { eur } from '../../../domain/money';

@Injectable()
export class GlobalSearchUseCase {
  constructor(private readonly prisma: PrismaService) {}

  async execute(query: unknown): Promise<GlobalSearchResult[]> {
    const { q } = globalSearchSchema.parse(query);

    const [payments, users, links] = await Promise.all([
      this.prisma.payment.findMany({
        where: {
          OR: [
            { id: { contains: q, mode: 'insensitive' } },
            { yapilyPaymentId: { contains: q, mode: 'insensitive' } },
          ],
        },
        take: 5,
      }),
      this.prisma.user.findMany({
        where: {
          OR: [
            { email: { contains: q, mode: 'insensitive' } },
            { displayName: { contains: q, mode: 'insensitive' } },
          ],
        },
        take: 5,
      }),
      this.prisma.paymentLink.findMany({
        where: { shortCode: { contains: q, mode: 'insensitive' } },
        take: 5,
      }),
    ]);

    const results: GlobalSearchResult[] = [];
    for (const p of payments) {
      results.push({
        type: 'payment',
        id: p.id,
        label: `${eur(p.amountCents)} · ${p.status}`,
        sub: p.yapilyPaymentId ?? p.id,
      });
    }
    for (const u of users) {
      results.push({
        type: 'user',
        id: u.id,
        label: u.displayName ?? u.email,
        sub: u.email,
      });
    }
    for (const l of links) {
      results.push({
        type: 'payment_link',
        id: l.id,
        label: `/${l.shortCode}`,
        sub: l.description ?? l.status,
      });
    }
    return results;
  }
}
