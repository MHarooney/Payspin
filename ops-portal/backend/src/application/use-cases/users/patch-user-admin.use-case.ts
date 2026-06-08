import { ConflictException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { patchUserAdminSchema } from '@payspin/validators';
import { AdminRole } from '@payspin/shared-types';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { AuditService } from '../../../infrastructure/audit/audit.service';
import { AuditAction } from '../../../domain/constants';
import { AdminRequestContext } from '../../../interfaces/http/decorators/current-admin.decorator';

@Injectable()
export class PatchUserAdminUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
  ) {}

  async execute(userId: string, body: unknown, ctx: AdminRequestContext): Promise<{ id: string }> {
    const input = patchUserAdminSchema.parse(body);
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');

    // Email change is SUPER_ADMIN only
    if (input.email !== undefined && ctx.role !== AdminRole.SUPER_ADMIN) {
      throw new ForbiddenException('Only SUPER_ADMIN can change a user\'s email');
    }

    if (input.email) {
      const lower = input.email.toLowerCase();
      const conflict = await this.prisma.user.findUnique({ where: { email: lower } });
      if (conflict && conflict.id !== userId) {
        throw new ConflictException('Email already in use');
      }
    }

    const before = { email: user.email, displayName: user.displayName, phoneE164: user.phoneE164 };
    const updated = await this.prisma.user.update({
      where: { id: userId },
      data: {
        ...(input.email ? { email: input.email.toLowerCase() } : {}),
        ...(input.displayName !== undefined ? { displayName: input.displayName } : {}),
        ...(input.phoneE164 !== undefined ? { phoneE164: input.phoneE164 } : {}),
      },
    });

    await this.audit.record(
      { adminUserId: ctx.adminUserId, adminEmail: ctx.email, ip: ctx.ip, userAgent: ctx.userAgent },
      { action: AuditAction.USER_UPDATE, targetType: 'user', targetId: userId, before, after: { email: updated.email, displayName: updated.displayName, phoneE164: updated.phoneE164 } },
    );

    return { id: userId };
  }
}
