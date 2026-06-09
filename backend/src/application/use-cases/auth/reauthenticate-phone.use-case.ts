import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ReauthenticatePhoneResponse } from '@payspin/shared-types';
import { reauthenticatePhoneSchema } from '@payspin/validators';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { FirebaseAdminService } from '../../../infrastructure/firebase/firebase-admin.service';

@Injectable()
export class ReauthenticatePhoneUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly firebase: FirebaseAdminService,
  ) {}

  /**
   * Confirms the caller still controls the verified phone on their account.
   * Read-only — does not attach or update phone numbers (unlike verify-phone).
   */
  async execute(userId: string, body: unknown): Promise<ReauthenticatePhoneResponse> {
    const { idToken } = reauthenticatePhoneSchema.parse(body);

    if (!this.firebase.isEnabled()) {
      throw new BadRequestException('Phone verification is not configured on the server');
    }

    const decoded = await this.firebase.verifyIdToken(idToken);
    if (!decoded) {
      throw new UnauthorizedException('Could not verify your identity');
    }

    const tokenPhone = decoded.phone_number;
    if (!tokenPhone) {
      throw new BadRequestException('Token does not contain a verified phone number');
    }

    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user?.phoneE164 || !user.phoneVerifiedAt) {
      throw new BadRequestException('No verified phone on this account');
    }

    if (normalizeE164(tokenPhone) !== normalizeE164(user.phoneE164)) {
      throw new ForbiddenException('Could not verify your identity');
    }

    return { reauthenticated: true };
  }
}

function normalizeE164(phone: string): string {
  const digits = phone.replace(/\D/g, '');
  return `+${digits}`;
}
