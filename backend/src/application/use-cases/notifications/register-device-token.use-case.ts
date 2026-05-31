import { Injectable } from '@nestjs/common';
import { RegisterDeviceTokenResponse } from '@payspin/shared-types';
import { registerDeviceTokenSchema } from '@payspin/validators';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';

@Injectable()
export class RegisterDeviceTokenUseCase {
  constructor(private readonly prisma: PrismaService) {}

  async execute(userId: string, body: unknown): Promise<RegisterDeviceTokenResponse> {
    const { fcmToken, platform } = registerDeviceTokenSchema.parse(body ?? {});

    await this.prisma.deviceToken.upsert({
      where: { userId_fcmToken: { userId, fcmToken } },
      create: { userId, fcmToken, platform },
      update: { platform },
    });

    return { registered: true };
  }
}
