import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { AdminRole } from '@payspin/shared-types';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { AuditService } from '../../../infrastructure/audit/audit.service';
import { AuditAction } from '../../../domain/constants';
import { AdminRequestContext } from '../../../interfaces/http/decorators/current-admin.decorator';

@Injectable()
export class DeleteUserAdminUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
  ) {}

  async execute(userId: string, ctx: AdminRequestContext): Promise<{ deleted: true }> {
    if (ctx.role !== AdminRole.SUPER_ADMIN) {
      throw new ForbiddenException('Only SUPER_ADMIN can delete users');
    }

    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');
    if (user.deletedAt) throw new BadRequestException('User is already deleted');

    // Block delete if in-flight payments exist
    const inFlight = await this.prisma.payment.count({
      where: {
        paymentLink: { payeeUserId: userId },
        status: { in: ['AWAITING_AUTHORIZATION', 'PENDING', 'PROCESSING'] },
      },
    });
    if (inFlight > 0) {
      throw new BadRequestException(`Cannot delete user: ${inFlight} in-flight payment(s) exist`);
    }

    await this.prisma.user.update({
      where: { id: userId },
      data: { deletedAt: new Date() },
    });

    await this.audit.record(
      { adminUserId: ctx.adminUserId, adminEmail: ctx.email, ip: ctx.ip, userAgent: ctx.userAgent },
      { action: AuditAction.USER_DELETE, targetType: 'user', targetId: userId },
    );

    return { deleted: true };
  }
}
