import { Injectable, NotFoundException } from '@nestjs/common';
import { resetPasswordAdminSchema } from '@payspin/validators';
import * as bcrypt from 'bcrypt';
import { randomBytes } from 'crypto';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { AuditService } from '../../../infrastructure/audit/audit.service';
import { AuditAction } from '../../../domain/constants';
import { AdminRequestContext } from '../../../interfaces/http/decorators/current-admin.decorator';

@Injectable()
export class ResetPasswordAdminUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
  ) {}

  async execute(userId: string, body: unknown, ctx: AdminRequestContext): Promise<{ tempPassword: string }> {
    const input = resetPasswordAdminSchema.parse(body);
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');

    const tempPassword = input.tempPassword ?? randomBytes(8).toString('hex');
    const passwordHash = await bcrypt.hash(tempPassword, 10);

    await this.prisma.user.update({ where: { id: userId }, data: { passwordHash } });

    await this.audit.record(
      { adminUserId: ctx.adminUserId, adminEmail: ctx.email, ip: ctx.ip, userAgent: ctx.userAgent },
      { action: AuditAction.USER_RESET_PASSWORD, targetType: 'user', targetId: userId },
    );

    return { tempPassword };
  }
}
