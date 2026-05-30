import { ConflictException, Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Prisma } from '@prisma/client';
import { AuthResponse } from '@payspin/shared-types';
import { registerSchema } from '@payspin/validators';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { UsersMapper } from '../users/users.mapper';

@Injectable()
export class RegisterUserUseCase {
  private static readonly BCRYPT_ROUNDS = 12;

  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
  ) {}

  async execute(body: unknown): Promise<AuthResponse> {
    const parsed = registerSchema.parse(body);
    const existing = await this.prisma.user.findUnique({
      where: { email: parsed.email.toLowerCase() },
    });
    if (existing) {
      throw new ConflictException('Email already registered');
    }

    const passwordHash = await bcrypt.hash(parsed.password, RegisterUserUseCase.BCRYPT_ROUNDS);
    try {
      const user = await this.prisma.user.create({
        data: {
          email: parsed.email.toLowerCase(),
          passwordHash,
          displayName: parsed.displayName ?? null,
        },
      });
      return this.buildAuthResponse(user);
    } catch (error) {
      // Two concurrent registrations can both pass the pre-check; the unique
      // constraint is the real guard. Map it to a clean 409.
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        throw new ConflictException('Email already registered');
      }
      throw error;
    }
  }

  private buildAuthResponse(user: {
    id: string;
    email: string;
    displayName: string | null;
    createdAt: Date;
  }): AuthResponse {
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
