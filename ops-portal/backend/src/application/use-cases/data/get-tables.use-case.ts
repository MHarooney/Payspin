import { Injectable } from '@nestjs/common';
import { TableSummaryList, TableSummary } from '@payspin/shared-types';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import {
  DATA_EXPLORER_ALLOWLIST,
  TABLE_KEY_TO_MODEL,
  TABLE_DISPLAY_NAME,
  CONSUMER_TABLES,
} from '../../../interfaces/http/data/data.allowlist';

const CACHE_TTL = 60_000; // 60 seconds

interface Cache {
  tables: TableSummary[];
  cachedAt: number;
}

let tableCache: Cache | null = null;

@Injectable()
export class GetTablesUseCase {
  constructor(private readonly prisma: PrismaService) {}

  async execute(): Promise<TableSummaryList> {
    const now = Date.now();
    if (tableCache && now - tableCache.cachedAt < CACHE_TTL) {
      return {
        tables: tableCache.tables,
        cachedAt: new Date(tableCache.cachedAt).toISOString(),
      };
    }

    const tables = await Promise.all(
      DATA_EXPLORER_ALLOWLIST.map(async (tableKey): Promise<TableSummary> => {
        const model = TABLE_KEY_TO_MODEL[tableKey];
        const delegate = (this.prisma as unknown as Record<string, unknown>)[model] as {
          count: () => Promise<number>;
        };
        const rowCount = await delegate.count().catch(() => 0);
        return {
          tableKey,
          modelName: TABLE_DISPLAY_NAME[tableKey] ?? tableKey,
          dbTable: tableKey,
          rowCount,
          group: CONSUMER_TABLES.has(tableKey) ? 'consumer' : 'ops',
        };
      }),
    );

    tableCache = { tables, cachedAt: now };
    return { tables, cachedAt: new Date(now).toISOString() };
  }
}
