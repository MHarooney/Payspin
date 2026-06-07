import { Module } from '@nestjs/common';
import { CirclesAdminMapper } from '../../../application/use-cases/circles/circles-admin.mapper';
import { GetCircleDetailAdminUseCase } from '../../../application/use-cases/circles/get-circle-detail-admin.use-case';
import { ListCirclesAdminUseCase } from '../../../application/use-cases/circles/list-circles-admin.use-case';
import { CirclesController } from './circles.controller';

@Module({
  controllers: [CirclesController],
  providers: [ListCirclesAdminUseCase, GetCircleDetailAdminUseCase, CirclesAdminMapper],
})
export class CirclesModule {}
