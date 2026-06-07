import { Injectable } from '@nestjs/common';
import { DisputeDto } from '@payspin/shared-types';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';

@Injectable()
export class ListDisputesUseCase {
  constructor(private readonly prisma: PrismaService) {}

  async execute(): Promise<DisputeDto[]> {
    const rows = await this.prisma.dispute.findMany({
      orderBy: { createdAt: 'desc' },
      take: 100,
    });
    return rows.map((d) => ({
      id: d.id,
      caseRef: d.caseRef,
      type: d.type,
      amountCents: d.amountCents,
      currency: d.currency,
      parties: d.parties,
      status: d.status,
      createdAt: d.createdAt.toISOString(),
    }));
  }
}
