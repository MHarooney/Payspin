import { ConflictException, Injectable } from '@nestjs/common';
import { CreateUserAdminResult } from '@payspin/shared-types';
import { createUserAdminSchema } from '@payspin/validators';
import * as bcrypt from 'bcrypt';
import { randomBytes } from 'crypto';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { AuditService } from '../../../infrastructure/audit/audit.service';
import { AuditAction } from '../../../domain/constants';
import { AdminRequestContext } from '../../../interfaces/http/decorators/current-admin.decorator';

@Injectable()
export class CreateUserAdminUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
  ) {}

  async execute(body: unknown, ctx: AdminRequestContext): Promise<CreateUserAdminResult> {
    const input = createUserAdminSchema.parse(body);
    const email = input.email.toLowerCase();

    const existing = await this.prisma.user.findFirst({
      where: { email },
    });
    if (existing) {
      throw new ConflictException('A user with that email already exists');
    }

    const tempPassword = input.tempPassword ?? randomBytes(8).toString('hex');
    const passwordHash = await bcrypt.hash(tempPassword, 10);

    const user = await this.prisma.user.create({
      data: {
        email,
        passwordHash,
        displayName: input.displayName ?? null,
        phoneE164: input.phoneE164 ?? null,
      },
    });

    await this.audit.record(
      { adminUserId: ctx.adminUserId, adminEmail: ctx.email, ip: ctx.ip, userAgent: ctx.userAgent },
      { action: AuditAction.USER_CREATE, targetType: 'user', targetId: user.id, after: { email, displayName: user.displayName } },
    );

    return { id: user.id, email: user.email, displayName: user.displayName, tempPassword };
  }
}
