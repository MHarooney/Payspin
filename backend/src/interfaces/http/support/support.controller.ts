import { Body, Controller, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { CreateSupportThreadUseCase } from '../../../application/use-cases/support/create-support-thread.use-case';
import { GetSupportUnreadCountUseCase } from '../../../application/use-cases/support/get-support-unread-count.use-case';
import { GetUserSupportThreadUseCase } from '../../../application/use-cases/support/get-user-support-thread.use-case';
import { ListUserSupportThreadsUseCase } from '../../../application/use-cases/support/list-user-support-threads.use-case';
import { MarkSupportThreadReadUseCase } from '../../../application/use-cases/support/mark-support-thread-read.use-case';
import { SendUserSupportMessageUseCase } from '../../../application/use-cases/support/send-user-support-message.use-case';
import { CurrentUser } from '../decorators/current-user.decorator';
import { JwtAuthGuard } from '../guards/jwt-auth.guard';
import { AuthenticatedUser } from '../guards/jwt.strategy';

@Controller('support')
@UseGuards(JwtAuthGuard)
export class SupportController {
  constructor(
    private readonly listThreads: ListUserSupportThreadsUseCase,
    private readonly createThread: CreateSupportThreadUseCase,
    private readonly getThread: GetUserSupportThreadUseCase,
    private readonly sendMessage: SendUserSupportMessageUseCase,
    private readonly markRead: MarkSupportThreadReadUseCase,
    private readonly unreadCount: GetSupportUnreadCountUseCase,
  ) {}

  @Get('threads')
  list(@CurrentUser() user: AuthenticatedUser) {
    return this.listThreads.execute(user.userId);
  }

  @Post('threads')
  create(@CurrentUser() user: AuthenticatedUser, @Body() body: unknown) {
    return this.createThread.execute(user.userId, body);
  }

  @Get('unread-count')
  unread(@CurrentUser() user: AuthenticatedUser) {
    return this.unreadCount.execute(user.userId);
  }

  @Get('threads/:id')
  thread(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.getThread.execute(user.userId, id);
  }

  @Post('threads/:id/messages')
  message(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() body: unknown,
  ) {
    return this.sendMessage.execute(user.userId, id, body);
  }

  @Patch('threads/:id/read')
  read(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.markRead.execute(user.userId, id);
  }
}
