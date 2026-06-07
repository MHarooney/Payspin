import { Injectable } from '@nestjs/common';
import { DashboardPeriod, VolumeSeries } from '@payspin/shared-types';
import { dashboardQuerySchema } from '@payspin/validators';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { volumeBuckets } from '../../../domain/periods';

@Injectable()
export class GetVolumeSeriesUseCase {
  constructor(private readonly prisma: PrismaService) {}

  async execute(query: unknown): Promise<VolumeSeries> {
    const { period } = dashboardQuerySchema.parse(query);
    const buckets = volumeBuckets(period as DashboardPeriod);

    const points = await Promise.all(
      buckets.map(async (b) => {
        const agg = await this.prisma.payment.aggregate({
          _sum: { amountCents: true },
          _count: true,
          where: { status: 'COMPLETED', initiatedAt: { gte: b.start, lt: b.end } },
        });
        return {
          label: b.label,
          volumeCents: agg._sum.amountCents ?? 0,
          count: agg._count,
        };
      }),
    );

    return { period: period as DashboardPeriod, points };
  }
}
