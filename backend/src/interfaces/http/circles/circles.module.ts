import { Module } from '@nestjs/common';
import { ActivateCircleUseCase } from '../../../application/use-cases/circles/activate-circle.use-case';
import { AdvanceCircleRoundUseCase } from '../../../application/use-cases/circles/advance-circle-round.use-case';
import { CreateCircleContributionLinkUseCase } from '../../../application/use-cases/circles/create-circle-contribution-link.use-case';
import { CreateCircleUseCase } from '../../../application/use-cases/circles/create-circle.use-case';
import { GetCircleByIdUseCase } from '../../../application/use-cases/circles/get-circle-by-id.use-case';
import { JoinCircleUseCase } from '../../../application/use-cases/circles/join-circle.use-case';
import { ListCirclesUseCase } from '../../../application/use-cases/circles/list-circles.use-case';
import { UpdateCircleMemberUseCase } from '../../../application/use-cases/circles/update-circle-member.use-case';
import { CirclesMapper } from '../../../application/use-cases/circles/circles.mapper';
import { PaymentLinksModule } from '../payment-links/payment-links.module';
import { CirclesController } from './circles.controller';

@Module({
  imports: [PaymentLinksModule],
  controllers: [CirclesController],
  providers: [
    CirclesMapper,
    CreateCircleUseCase,
    ListCirclesUseCase,
    GetCircleByIdUseCase,
    JoinCircleUseCase,
    UpdateCircleMemberUseCase,
    ActivateCircleUseCase,
    AdvanceCircleRoundUseCase,
    CreateCircleContributionLinkUseCase,
  ],
})
export class CirclesModule {}
