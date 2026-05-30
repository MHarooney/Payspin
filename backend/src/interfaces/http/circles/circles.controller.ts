import { Body, Controller, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { PaymentLinkSummary } from '@payspin/shared-types';
import { ActivateCircleUseCase } from '../../../application/use-cases/circles/activate-circle.use-case';
import { AdvanceCircleRoundUseCase } from '../../../application/use-cases/circles/advance-circle-round.use-case';
import { CreateCircleContributionLinkUseCase } from '../../../application/use-cases/circles/create-circle-contribution-link.use-case';
import { CreateCircleUseCase } from '../../../application/use-cases/circles/create-circle.use-case';
import { GetCircleByIdUseCase } from '../../../application/use-cases/circles/get-circle-by-id.use-case';
import { JoinCircleUseCase } from '../../../application/use-cases/circles/join-circle.use-case';
import { ListCirclesUseCase } from '../../../application/use-cases/circles/list-circles.use-case';
import { UpdateCircleMemberUseCase } from '../../../application/use-cases/circles/update-circle-member.use-case';
import { CurrentUser } from '../decorators/current-user.decorator';
import { JwtAuthGuard } from '../guards/jwt-auth.guard';
import { AuthenticatedUser } from '../guards/jwt.strategy';

@Controller('circles')
@UseGuards(JwtAuthGuard)
export class CirclesController {
  constructor(
    private readonly createCircle: CreateCircleUseCase,
    private readonly listCircles: ListCirclesUseCase,
    private readonly joinCircle: JoinCircleUseCase,
    private readonly getCircle: GetCircleByIdUseCase,
    private readonly updateMember: UpdateCircleMemberUseCase,
    private readonly activateCircle: ActivateCircleUseCase,
    private readonly advanceRound: AdvanceCircleRoundUseCase,
    private readonly createContributionLink: CreateCircleContributionLinkUseCase,
  ) {}

  @Post()
  create(@CurrentUser() user: AuthenticatedUser, @Body() body: unknown) {
    return this.createCircle.execute(user.userId, body);
  }

  @Get()
  list(@CurrentUser() user: AuthenticatedUser) {
    return this.listCircles.execute(user.userId);
  }

  @Post('join')
  join(@CurrentUser() user: AuthenticatedUser, @Body() body: unknown) {
    return this.joinCircle.execute(user.userId, body);
  }

  @Get(':id')
  get(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.getCircle.execute(user.userId, id);
  }

  @Patch(':id/members/:memberId')
  patchMember(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Param('memberId') memberId: string,
    @Body() body: unknown,
  ) {
    return this.updateMember.execute(user.userId, id, memberId, body);
  }

  @Post(':id/activate')
  activate(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.activateCircle.execute(user.userId, id);
  }

  @Post(':id/advance-round')
  advance(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.advanceRound.execute(user.userId, id);
  }

  @Post(':id/contribution-link')
  contributionLink(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
  ): Promise<PaymentLinkSummary> {
    return this.createContributionLink.execute(user.userId, id);
  }
}
