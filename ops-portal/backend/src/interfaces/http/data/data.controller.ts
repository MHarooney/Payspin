import { Controller, Get, Param, Query, UseGuards } from '@nestjs/common';
import { AdminRole } from '@payspin/shared-types';
import { GetSchemaUseCase } from '../../../application/use-cases/data/get-schema.use-case';
import { GetTablesUseCase } from '../../../application/use-cases/data/get-tables.use-case';
import { GetTableRowsUseCase } from '../../../application/use-cases/data/get-table-rows.use-case';
import { CurrentAdmin, AdminRequestContext } from '../decorators/current-admin.decorator';
import { AdminJwtAuthGuard } from '../guards/admin-jwt-auth.guard';
import { RolesGuard } from '../guards/roles.guard';
import { Roles } from '../guards/roles.decorator';
import { Throttle } from '@nestjs/throttler';

@Controller('data')
@UseGuards(AdminJwtAuthGuard, RolesGuard)
export class DataController {
  constructor(
    private readonly getSchema: GetSchemaUseCase,
    private readonly getTables: GetTablesUseCase,
    private readonly getTableRows: GetTableRowsUseCase,
  ) {}

  /** GET /admin/v1/data/schema — available to all authenticated roles */
  @Get('schema')
  schema() {
    return this.getSchema.execute();
  }

  /** GET /admin/v1/data/tables — available to all authenticated roles */
  @Get('tables')
  tables() {
    return this.getTables.execute();
  }

  /**
   * GET /admin/v1/data/tables/:tableKey/rows
   * Restricted to OPS+ to prevent bulk data extraction by READ_ONLY accounts.
   * Tighter throttle: 30 req/min per admin (vs global 200).
   */
  @Get('tables/:tableKey/rows')
  @Roles(AdminRole.SUPER_ADMIN, AdminRole.OPS)
  @Throttle({ default: { ttl: 60_000, limit: 30 } })
  rows(
    @Param('tableKey') tableKey: string,
    @Query() query: unknown,
    @CurrentAdmin() admin: AdminRequestContext,
  ) {
    return this.getTableRows.execute(tableKey, query, admin);
  }
}
