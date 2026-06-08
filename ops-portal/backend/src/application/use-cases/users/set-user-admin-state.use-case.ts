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

    const data: Record<string, unknown> = {
      updatedByEmail: ctx.email,
    };
    if (input.status !== undefined) {
      data.status = input.status;
      if (input.status === 'FROZEN') {
        data.frozenReason = input.reason;
      }
    }
    if (input.kycStatus !== undefined) data.kycStatus = input.kycStatus;
    if (input.kycTier !== undefined) data.kycTier = input.kycTier;
    if (input.riskLevel !== undefined) data.riskLevel = input.riskLevel;
    if (input.note !== undefined) data.note = input.note;

    const after = await this.prisma.userAdminState.upsert({
      where: { userId },
      create: {
        userId,
        status: 'ACTIVE',
        kycStatus: 'PENDING',
        riskLevel: 'LOW',
        ...data,
      },
      update: data,
    });

    const action =
      input.status === 'FROZEN'
        ? AuditAction.USER_FREEZE
        : input.kycStatus === 'VERIFIED'
          ? AuditAction.KYC_APPROVE
          : input.note !== undefined
            ? AuditAction.USER_STATE_UPDATE
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
