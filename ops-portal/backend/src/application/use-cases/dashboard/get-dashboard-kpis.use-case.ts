import { Injectable } from '@nestjs/common';
import { DashboardKpis, DashboardPeriod } from '@payspin/shared-types';
import { dashboardQuerySchema } from '@payspin/validators';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { periodRanges, Range } from '../../../domain/periods';
import { eur, trendPct } from '../../../domain/money';

@Injectable()
export class GetDashboardKpisUseCase {
  constructor(private readonly prisma: PrismaService) {}

  async execute(query: unknown): Promise<DashboardKpis> {
    const { period } = dashboardQuerySchema.parse(query);
    const { current, previous } = periodRanges(period as DashboardPeriod);

    const [cur, prev, signups, prevSignups, inFlight] = await Promise.all([
      this.windowStats(current),
      this.windowStats(previous),
      this.prisma.user.count({ where: { createdAt: { gte: current.start, lt: current.end } } }),
      this.prisma.user.count({ where: { createdAt: { gte: previous.start, lt: previous.end } } }),
      this.prisma.payment.aggregate({
        _sum: { amountCents: true },
        _count: true,
        where: { status: { in: ['AWAITING_AUTHORIZATION', 'PENDING', 'PROCESSING'] } },
      }),
    ]);

    const volTrend = trendPct(cur.volumeCents, prev.volumeCents);
    const txTrend = trendPct(cur.count, prev.count);
    const srTrend = trendPct(cur.successRate, prev.successRate);
    const signupTrend = trendPct(signups, prevSignups);

    return {
      period: period as DashboardPeriod,
      kpis: [
        { label: 'Volume', value: eur(cur.volumeCents), ...volTrend },
        { label: 'Transactions', value: cur.count.toLocaleString(), ...txTrend },
        {
          label: 'Success Rate',
          value: `${cur.successRate.toFixed(1)}%`,
          ...srTrend,
        },
        {
          label: 'Funds in Flight',
          value: eur(inFlight._sum.amountCents ?? 0),
          trend: `${inFlight._count} pending`,
          direction: 'flat',
        },
        { label: 'New Signups', value: signups.toLocaleString(), ...signupTrend },
      ],
    };
  }

  private async windowStats(range: Range) {
    const [completed, failed] = await Promise.all([
      this.prisma.payment.aggregate({
        _sum: { amountCents: true },
        _count: true,
        where: { status: 'COMPLETED', initiatedAt: { gte: range.start, lt: range.end } },
      }),
      this.prisma.payment.count({
        where: { status: 'FAILED', initiatedAt: { gte: range.start, lt: range.end } },
      }),
    ]);
    const completedCount = completed._count;
    const total = completedCount + failed;
    return {
      volumeCents: completed._sum.amountCents ?? 0,
      count: completedCount,
      successRate: total === 0 ? 100 : (completedCount / total) * 100,
    };
  }
}
