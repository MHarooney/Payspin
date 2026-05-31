import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import {
  FirebaseAdminService,
  PushPayload,
} from '../../../infrastructure/firebase/firebase-admin.service';

@Injectable()
export class SendPushNotificationUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly firebase: FirebaseAdminService,
  ) {}

  /**
   * Sends an FCM push to every device registered for the user, then prunes any
   * tokens FCM reports as unregistered/invalid. No-ops when Firebase is disabled
   * or the user has no devices.
   */
  async execute(userId: string, payload: PushPayload): Promise<{ sent: number }> {
    const devices = await this.prisma.deviceToken.findMany({ where: { userId } });
    if (devices.length === 0) return { sent: 0 };

    const tokens = devices.map((d) => d.fcmToken);
    const { sent, invalidTokens } = await this.firebase.sendToTokens(tokens, payload);

    if (invalidTokens.length > 0) {
      await this.prisma.deviceToken.deleteMany({
        where: { userId, fcmToken: { in: invalidTokens } },
      });
    }

    return { sent };
  }
}
