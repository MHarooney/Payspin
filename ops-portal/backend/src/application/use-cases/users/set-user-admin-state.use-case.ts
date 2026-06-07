import { Injectable, NotFoundException } from '@nestjs/common';
import { setUserAdminStateSchema } from '@payspin/validators';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { AuditService } from '../../../infrastructure/audit/audit.service';
import { AuditAction } from '../../../domain/constants';
import { AdminRequestContext } from '../../../interfaces/http/decorators/current-admin.decorator';

@Injectable()
export class SetUserAdminStateUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
  ) {}

  async execute(userId: string, body: unknown, ctx: AdminRequestContext) {
    const input = setUserAdminStateSchema.parse(body);
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException('User not found');
    }

    const before = await this.prisma.userAdminState.findUnique({ where: { userId } });

    const data = {
      status: input.status,
      kycStatus: input.kycStatus,
      kycTier: input.kycTier,
      riskLevel: input.riskLevel,
      frozenReason: input.status === 'FROZEN' ? input.reason : undefined,
      updatedByEmail: ctx.email,
    };

    const after = await this.prisma.userAdminState.upsert({
      where: { userId },
      create: { userId, ...data },
      update: data,
    });

    const action =
      input.status === 'FROZEN'
        ? AuditAction.USER_FREEZE
        : input.kycStatus === 'VERIFIED'
          ? AuditAction.KYC_APPROVE
          : AuditAction.USER_STATE_UPDATE;

    await this.audit.record(
      { adminUserId: ctx.adminUserId, adminEmail: ctx.email, ip: ctx.ip, userAgent: ctx.userAgent },
      {
        action,
        targetType: 'user',
        targetId: userId,
        before: before ?? undefined,
        after,
      },
    );

    return after;
  }
}
