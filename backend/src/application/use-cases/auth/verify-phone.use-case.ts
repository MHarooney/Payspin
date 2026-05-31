import { BadRequestException, Injectable, UnauthorizedException } from '@nestjs/common';
import { VerifyPhoneResponse } from '@payspin/shared-types';
import { verifyPhoneSchema } from '@payspin/validators';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { FirebaseAdminService } from '../../../infrastructure/firebase/firebase-admin.service';

@Injectable()
export class VerifyPhoneUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly firebase: FirebaseAdminService,
  ) {}

  /**
   * Confirms a Firebase Phone Auth result for an already-authenticated (JWT)
   * payee and stores the verified E.164 number on their profile. Email/password
   * stays the primary identity; this only attaches a verified phone.
   */
  async execute(userId: string, body: unknown): Promise<VerifyPhoneResponse> {
    const { idToken } = verifyPhoneSchema.parse(body);

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

    const updated = await this.prisma.user.update({
      where: { id: userId },
      data: { phoneE164: phone, phoneVerifiedAt: new Date() },
    });

    return {
      phoneVerified: true,
      phoneVerifiedAt: updated.phoneVerifiedAt?.toISOString() ?? null,
    };
  }
}
