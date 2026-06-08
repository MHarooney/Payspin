import { Module } from '@nestjs/common';
import { GetSchemaUseCase } from '../../../application/use-cases/data/get-schema.use-case';
import { GetTablesUseCase } from '../../../application/use-cases/data/get-tables.use-case';
import { GetTableRowsUseCase } from '../../../application/use-cases/data/get-table-rows.use-case';
import { DataController } from './data.controller';

@Module({
  controllers: [DataController],
  providers: [GetSchemaUseCase, GetTablesUseCase, GetTableRowsUseCase],
})
export class DataModule {}
