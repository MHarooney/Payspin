import { BadRequestException, Injectable } from '@nestjs/common';
import { TableRowsPreview } from '@payspin/shared-types';
import { tableRowsQuerySchema } from '@payspin/validators';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { AuditService } from '../../../infrastructure/audit/audit.service';
import { AuditAction } from '../../../domain/constants';
import { AdminRequestContext } from '../../../interfaces/http/decorators/current-admin.decorator';
import {
  DATA_EXPLORER_ALLOWLIST,
  TABLE_KEY_TO_MODEL,
  redactRow,
} from '../../../interfaces/http/data/data.allowlist';

const ALLOWED_SET = new Set<string>(DATA_EXPLORER_ALLOWLIST);

@Injectable()
export class GetTableRowsUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
  ) {}

  async execute(
    tableKey: string,
    query: unknown,
    ctx: AdminRequestContext,
  ): Promise<TableRowsPreview> {
    if (!ALLOWED_SET.has(tableKey)) {
      throw new BadRequestException(`Table '${tableKey}' is not available for browsing`);
    }

    const { page, pageSize } = tableRowsQuerySchema.parse(query);

    const model = TABLE_KEY_TO_MODEL[tableKey];
    const delegate = (this.prisma as unknown as Record<string, unknown>)[model] as {
      count: (opts?: object) => Promise<number>;
      findMany: (opts: object) => Promise<Record<string, unknown>[]>;
    };

    const orderBy = { createdAt: 'desc' };
    const [total, rawRows] = await Promise.all([
      delegate.count(),
      delegate
        .findMany({
          take: pageSize,
          skip: (page - 1) * pageSize,
          orderBy,
        })
        .catch(() =>
          delegate.findMany({ take: pageSize, skip: (page - 1) * pageSize }),
        ),
    ]);

    const rows = rawRows.map((row) => redactRow(row));
    const columns = rows.length > 0 ? Object.keys(rows[0]) : [];

    await this.audit.record(
      {
        adminUserId: ctx.adminUserId,
        adminEmail: ctx.email,
        ip: ctx.ip,
        userAgent: ctx.userAgent,
      },
      {
        action: AuditAction.DATA_TABLE_VIEW,
        targetType: 'table',
        targetId: tableKey,
      },
    );

    return {
      tableKey,
      columns,
      rows,
      total,
      page,
      pageSize,
      totalPages: Math.ceil(total / pageSize),
    };
  }
}
