import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { AdminLoginResponse, AdminProfile, AdminRole } from '@payspin/shared-types';
import { adminLoginSchema } from '@payspin/validators';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { AuditService } from '../../../infrastructure/audit/audit.service';
import { AuditAction } from '../../../domain/constants';

@Injectable()
export class AdminLoginUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
    private readonly audit: AuditService,
  ) {}

  async execute(body: unknown, ip?: string, userAgent?: string): Promise<AdminLoginResponse> {
    const { email, password } = adminLoginSchema.parse(body);
    const admin = await this.prisma.adminUser.findUnique({
      where: { email: email.toLowerCase() },
    });
    if (!admin || !admin.isActive) {
      throw new UnauthorizedException('Invalid email or password');
    }

    const valid = await bcrypt.compare(password, admin.passwordHash);
    if (!valid) {
      throw new UnauthorizedException('Invalid email or password');
    }

    await this.prisma.adminUser.update({
      where: { id: admin.id },
      data: { lastLoginAt: new Date() },
    });

    await this.audit.record(
      { adminUserId: admin.id, adminEmail: admin.email, ip, userAgent },
      { action: AuditAction.ADMIN_LOGIN, targetType: 'admin_user', targetId: admin.id },
    );

    const expiresIn = this.config.get<string>('ADMIN_JWT_EXPIRES_IN') ?? '15m';
    const accessToken = this.jwt.sign({
      sub: admin.id,
      email: admin.email,
      role: admin.role as AdminRole,
    });

    const profile: AdminProfile = {
      id: admin.id,
      email: admin.email,
      displayName: admin.displayName,
      role: admin.role as AdminRole,
      lastLoginAt: admin.lastLoginAt?.toISOString() ?? null,
    };

    return { accessToken, expiresIn, admin: profile };
  }
}
