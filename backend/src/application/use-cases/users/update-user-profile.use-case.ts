import { Injectable } from '@nestjs/common';
import { UserProfile } from '@payspin/shared-types';
import { updateUserSchema } from '@payspin/validators';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { UsersMapper } from './users.mapper';

@Injectable()
export class UpdateUserProfileUseCase {
  constructor(private readonly prisma: PrismaService) {}

  async execute(userId: string, body: unknown): Promise<UserProfile> {
    const parsed = updateUserSchema.parse(body);
    const user = await this.prisma.user.update({
      where: { id: userId },
      data: { displayName: parsed.displayName ?? null },
    });
    return UsersMapper.toProfile(user);
  }
}
