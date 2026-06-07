import { Injectable } from '@nestjs/common';
import { ReconciliationException } from '@payspin/shared-types';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { eur } from '../../../domain/money';

/**
 * Phase 2: until a Yapily settlement feed is wired, "exceptions" surface payments
 * that the ledger considers in-progress but the bank has not confirmed. These are
 * real rows from Postgres; true ledger-vs-bank variance lands when settlement sync
 * exists.
 */
@Injectable()
export class ListReconciliationExceptionsUseCase {
  constructor(private readonly prisma: PrismaService) {}

  async execute(): Promise<ReconciliationException[]> {
    const stuck = await this.prisma.payment.findMany({
      where: { status: { in: ['PROCESSING', 'PENDING', 'AWAITING_AUTHORIZATION'] } },
      orderBy: { initiatedAt: 'asc' },
      take: 50,
    });

    return stuck.map((p) => ({
      id: p.id,
      txId: p.id,
      ledger: `${eur(p.amountCents)} ${p.status.toLowerCase()}`,
      bank: p.yapilyPaymentId ? 'not confirmed' : 'no bank ref',
      deltaCents: p.amountCents,
      status: 'Unmatched',
    }));
  }
}
