import { UserProfile } from '@payspin/shared-types';

export class UsersMapper {
  static toProfile(user: {
    id: string;
    email: string;
    displayName: string | null;
    phoneE164?: string | null;
    phoneVerifiedAt?: Date | null;
    createdAt: Date;
  }): UserProfile {
    return {
      id: user.id,
      email: user.email,
      displayName: user.displayName,
      phoneE164: user.phoneE164 ?? null,
      phoneVerified: user.phoneVerifiedAt != null,
      createdAt: user.createdAt.toISOString(),
    };
  }
}
