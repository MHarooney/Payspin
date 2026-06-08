import { Controller, Get, Param, Query, UseGuards } from '@nestjs/common';
import { GetCircleDetailAdminUseCase } from '../../../application/use-cases/circles/get-circle-detail-admin.use-case';
import { ListCirclesAdminUseCase } from '../../../application/use-cases/circles/list-circles-admin.use-case';
import { AdminJwtAuthGuard } from '../guards/admin-jwt-auth.guard';

@Controller('circles')
@UseGuards(AdminJwtAuthGuard)
export class CirclesController {
  constructor(
    private readonly listCircles: ListCirclesAdminUseCase,
    private readonly getDetail: GetCircleDetailAdminUseCase,
  ) {}

  @Get()
  list(@Query() query: unknown) {
    return this.listCircles.execute(query);
  }

  @Get(':id')
  detail(@Param('id') id: string) {
    return this.getDetail.execute(id);
  }
}
