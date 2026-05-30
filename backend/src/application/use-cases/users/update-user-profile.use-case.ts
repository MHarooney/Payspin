import { Injectable } from '@nestjs/common';
import { UserProfile } from '@payspin/shared-types';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { UsersMapper } from './users.mapper';

@Injectable()
export class UpdateUserProfileUseCase {
  constructor(private readonly prisma: PrismaService) {}

  async execute(userId: string, displayName: string): Promise<UserProfile> {
    const user = await this.prisma.user.update({
      where: { id: userId },
      data: { displayName },
    });
    return UsersMapper.toProfile(user);
  }
}
