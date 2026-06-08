import {
  BadRequestException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Prisma } from '@prisma/client';
import { AuthResponse } from '@payspin/shared-types';
import { phoneSignInSchema } from '@payspin/validators';
import * as bcrypt from 'bcrypt';
import { randomBytes } from 'crypto';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { FirebaseAdminService } from '../../../infrastructure/firebase/firebase-admin.service';
import { UsersMapper } from '../users/users.mapper';

/**
 * Phone-first authentication: verify a Firebase Phone Auth ID token and resolve
 * it to a single Payspin account keyed on the *verified* E.164 number. Existing
 * phone → log in; new phone → create once. This is the only correct identity
 * for phone onboarding — deriving identity from the locally-typed digits let the
 * same real number create multiple accounts (e.g. with/without a leading zero).
 */
@Injectable()
export class PhoneSignInUseCase {
  private static readonly BCRYPT_ROUNDS = 12;

  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    private readonly firebase: FirebaseAdminService,
  ) {}

  async execute(body: unknown): Promise<AuthResponse> {
    const { idToken, displayName } = phoneSignInSchema.parse(body);

    if (!this.firebase.isEnabled()) {
      throw new BadRequestException('Phone verification is not configured on the server');
    }

    const decoded = await this.firebase.verifyIdToken(idToken);
    if (!decoded) {
      throw new UnauthorizedException('Invalid phone verification token');
    }

    const phone = decoded.phone_number;
    if (!phone) {
      throw new BadRequestException('Token does not contain a verified phone number');
    }

    // Earliest account wins as the canonical identity if historical duplicates
    // exist; future sign-ins always converge on it.
    const existing = await this.prisma.user.findFirst({
      where: { phoneE164: phone },
      orderBy: { createdAt: 'asc' },
    });
    if (existing) {
      if (existing.deletedAt) {
        throw new UnauthorizedException('Account not found');
      }
      const adminState = await this.prisma.userAdminState.findUnique({ where: { userId: existing.id } });
      if (adminState?.status === 'FROZEN' || adminState?.status === 'SUSPENDED' || adminState?.status === 'BLOCKED') {
        throw new UnauthorizedException('Account is temporarily restricted');
      }
      const user = existing.phoneVerifiedAt
        ? existing
        : await this.prisma.user.update({
            where: { id: existing.id },
            data: { phoneVerifiedAt: new Date() },
          });
      return this.buildAuthResponse(user);
    }

    // Synthetic login email derived from the canonical E.164 digits so it is
    // stable per phone number and never collides for the same person.
    const email = `${phone.replace(/\D/g, '')}@phone.payspin.app`;
    const passwordHash = await bcrypt.hash(randomBytes(32).toString('hex'), PhoneSignInUseCase.BCRYPT_ROUNDS);

    try {
      const user = await this.prisma.user.create({
        data: {
          email,
          passwordHash,
          displayName: displayName ?? null,
          phoneE164: phone,
          phoneVerifiedAt: new Date(),
        },
      });
      return this.buildAuthResponse(user);
    } catch (error) {
      // A concurrent sign-in for the same number can win the race; fall back to
      // the account it created so the caller still gets a session.
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        const raced = await this.prisma.user.findFirst({
          where: { phoneE164: phone },
          orderBy: { createdAt: 'asc' },
        });
        if (raced) return this.buildAuthResponse(raced);
      }
      throw error;
    }
  }

  private async buildAuthResponse(user: {
    id: string;
    email: string;
    displayName: string | null;
    phoneE164: string | null;
    phoneVerifiedAt: Date | null;
    createdAt: Date;
  }): Promise<AuthResponse> {
    const now = new Date();
    await this.prisma.user.update({
      where: { id: user.id },
      data: { lastLoginAt: now, lastSeenAt: now },
    });
    const accessToken = this.jwtService.sign({ sub: user.id, email: user.email });
    return {
      accessToken,
      user: UsersMapper.toProfile(user),
    };
  }
}
