import { Body, Controller, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { ListNotificationsUseCase } from '../../../application/use-cases/notifications/list-notifications.use-case';
import { MarkNotificationReadUseCase } from '../../../application/use-cases/notifications/mark-notification-read.use-case';
import { RegisterDeviceTokenUseCase } from '../../../application/use-cases/notifications/register-device-token.use-case';
import { CurrentUser } from '../decorators/current-user.decorator';
import { JwtAuthGuard } from '../guards/jwt-auth.guard';
import { AuthenticatedUser } from '../guards/jwt.strategy';

@Controller('notifications')
@UseGuards(JwtAuthGuard)
export class NotificationsController {
  constructor(
    private readonly list: ListNotificationsUseCase,
    private readonly markRead: MarkNotificationReadUseCase,
    private readonly registerDeviceToken: RegisterDeviceTokenUseCase,
  ) {}

  @Get()
  index(
    @CurrentUser() user: AuthenticatedUser,
    @Query('cursor') cursor?: string,
    @Query('limit') limit?: string,
  ) {
    return this.list.execute(user.userId, {
      cursor,
      limit: limit !== undefined ? Number(limit) : undefined,
    });
  }

  @Post('read-all')
  readAll(@CurrentUser() user: AuthenticatedUser) {
    return this.markRead.markAll(user.userId);
  }

  @Post(':id/read')
  read(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.markRead.execute(user.userId, id);
  }

  @Post('device-token')
  device(@CurrentUser() user: AuthenticatedUser, @Body() body: unknown) {
    return this.registerDeviceToken.execute(user.userId, body);
  }
}
