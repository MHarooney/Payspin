import { Module } from '@nestjs/common';
import { AdminUsersController } from './admin-users.controller';

@Module({
  controllers: [AdminUsersController],
  // PrismaService and AuditService are @Global() — no extra providers needed
})
export class AdminUsersModule {}
