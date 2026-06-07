import { Body, Controller, Get, Post, Req, UseGuards } from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { AdminProfile, AdminRole } from '@payspin/shared-types';
import type { Request } from 'express';
import { AdminLoginUseCase } from '../../../application/use-cases/auth/admin-login.use-case';
import { CurrentAdmin, AdminRequestContext } from '../decorators/current-admin.decorator';
import { AdminJwtAuthGuard } from '../guards/admin-jwt-auth.guard';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';

@Controller('auth')
export class AuthController {
  constructor(
    private readonly adminLogin: AdminLoginUseCase,
    private readonly prisma: PrismaService,
  ) {}

  @Post('login')
  @Throttle({ default: { limit: 15, ttl: 60000 } })
  login(@Body() body: unknown, @Req() req: Request) {
    return this.adminLogin.execute(body, req.ip, req.get('user-agent') ?? undefined);
  }

  @Get('me')
  @UseGuards(AdminJwtAuthGuard)
  async me(@CurrentAdmin() admin: AdminRequestContext): Promise<AdminProfile> {
    const row = await this.prisma.adminUser.findUniqueOrThrow({
      where: { id: admin.adminUserId },
    });
    return {
      id: row.id,
      email: row.email,
      displayName: row.displayName,
      role: row.role as AdminRole,
      lastLoginAt: row.lastLoginAt?.toISOString() ?? null,
    };
  }
}
