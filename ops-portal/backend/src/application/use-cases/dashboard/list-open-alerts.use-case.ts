import { Injectable } from '@nestjs/common';
import { OpenAlert } from '@payspin/shared-types';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';

const SEVERITY: Record<string, OpenAlert['severity']> = {
  HIGH: 'HIGH',
  MEDIUM: 'MEDIUM',
  LOW: 'LOW',
};

@Injectable()
export class ListOpenAlertsUseCase {
  constructor(private readonly prisma: PrismaService) {}

  async execute(): Promise<OpenAlert[]> {
    const alerts = await this.prisma.complianceAlert.findMany({
      where: { status: { not: 'CLEARED' } },
      orderBy: { createdAt: 'desc' },
      take: 8,
    });

    return alerts.map((a) => ({
      id: a.id,
      title: a.type,
      detail: `${a.subject} · ${a.rule}`,
      severity: SEVERITY[a.severity] ?? 'LOW',
      status: a.status,
    }));
  }
}
