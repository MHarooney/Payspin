import { Injectable, NotFoundException } from '@nestjs/common';
import { UserTestSetupResult } from '@payspin/shared-types';
import { userTestSetupSchema } from '@payspin/validators';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { AdminRequestContext } from '../../../interfaces/http/decorators/current-admin.decorator';
import { CreatePaymentLinkAdminUseCase } from '../payment-links/create-payment-link-admin.use-case';
import { SetUserAdminStateUseCase } from '../users/set-user-admin-state.use-case';

@Injectable()
export class UserTestSetupAdminUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly setState: SetUserAdminStateUseCase,
    private readonly createLink: CreatePaymentLinkAdminUseCase,
  ) {}

  async execute(userId: string, body: unknown, ctx: AdminRequestContext): Promise<UserTestSetupResult> {
    const input = userTestSetupSchema.parse(body ?? {});
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user || user.deletedAt) {
      throw new NotFoundException('User not found');
    }

    await this.setState.execute(userId, { status: 'ACTIVE', kycStatus: 'VERIFIED' }, ctx);

    const paymentLink = await this.createLink.execute(
      {
        payeeUserId: userId,
        amountCents: input.amountCents,
        description: input.description ?? 'Ops test payment link',
      },
      ctx,
    );

    const state = await this.prisma.userAdminState.findUnique({ where: { userId } });

    return {
      userId,
      kycStatus: state?.kycStatus ?? 'VERIFIED',
      status: state?.status ?? 'ACTIVE',
      paymentLink,
    };
  }
}
