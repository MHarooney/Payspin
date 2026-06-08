import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { AuthResponse } from '@payspin/shared-types';
import { loginSchema } from '@payspin/validators';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { UsersMapper } from '../users/users.mapper';

@Injectable()
export class LoginUserUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
  ) {}

  async execute(body: unknown): Promise<AuthResponse> {
    const parsed = loginSchema.parse(body);
    const user = await this.prisma.user.findUnique({
      where: { email: parsed.email.toLowerCase() },
    });
    if (!user) {
      throw new UnauthorizedException('Invalid email or password');
    }
    if (user.deletedAt) {
      throw new UnauthorizedException('Account not found');
    }

    const valid = await bcrypt.compare(parsed.password, user.passwordHash);
    if (!valid) {
      throw new UnauthorizedException('Invalid email or password');
    }

    // Check frozen status via admin overlay
    const adminState = await this.prisma.userAdminState.findUnique({ where: { userId: user.id } });
    if (adminState?.status === 'FROZEN' || adminState?.status === 'SUSPENDED' || adminState?.status === 'BLOCKED') {
      throw new UnauthorizedException('Account is temporarily restricted');
    }

    const now = new Date();
    await this.prisma.user.update({
      where: { id: user.id },
      data: { lastLoginAt: now, lastSeenAt: now },
    });

    const accessToken = this.jwtService.sign({
      sub: user.id,
      email: user.email,
    });

    return {
      accessToken,
      user: UsersMapper.toProfile(user),
    };
  }
}
