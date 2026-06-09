import { Module } from '@nestjs/common';
import { CreateSupportThreadUseCase } from '../../../application/use-cases/support/create-support-thread.use-case';
import { GetSupportUnreadCountUseCase } from '../../../application/use-cases/support/get-support-unread-count.use-case';
import { GetUserSupportThreadUseCase } from '../../../application/use-cases/support/get-user-support-thread.use-case';
import { ListUserSupportThreadsUseCase } from '../../../application/use-cases/support/list-user-support-threads.use-case';
import { MarkSupportThreadReadUseCase } from '../../../application/use-cases/support/mark-support-thread-read.use-case';
import { SendUserSupportMessageUseCase } from '../../../application/use-cases/support/send-user-support-message.use-case';
import { SupportController } from './support.controller';

@Module({
  controllers: [SupportController],
  providers: [
    ListUserSupportThreadsUseCase,
    CreateSupportThreadUseCase,
    GetUserSupportThreadUseCase,
    SendUserSupportMessageUseCase,
    MarkSupportThreadReadUseCase,
    GetSupportUnreadCountUseCase,
  ],
})
export class SupportModule {}
