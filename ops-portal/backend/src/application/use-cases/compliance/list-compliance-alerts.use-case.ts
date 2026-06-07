import { Injectable } from '@nestjs/common';
import { ComplianceAlertDto } from '@payspin/shared-types';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';

@Injectable()
export class ListComplianceAlertsUseCase {
  constructor(private readonly prisma: PrismaService) {}

  async execute(): Promise<ComplianceAlertDto[]> {
    const rows = await this.prisma.complianceAlert.findMany({
      orderBy: { createdAt: 'desc' },
      take: 100,
    });
    return rows.map((a) => ({
      id: a.id,
      type: a.type,
      subject: a.subject,
      subjectRef: a.subjectRef,
      rule: a.rule,
      severity: a.severity,
      status: a.status,
      createdAt: a.createdAt.toISOString(),
    }));
  }
}
