import { UserProfile } from '@payspin/shared-types';

export class UsersMapper {
  static toProfile(user: {
    id: string;
    email: string;
    displayName: string | null;
    createdAt: Date;
  }): UserProfile {
    return {
      id: user.id,
      email: user.email,
      displayName: user.displayName,
      createdAt: user.createdAt.toISOString(),
    };
  }
}
