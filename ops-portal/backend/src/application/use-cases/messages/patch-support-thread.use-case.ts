import { Injectable } from '@nestjs/common';
import { patchSupportThreadSchema } from '@payspin/validators';
import { AuditAction } from '../../../domain/constants';
import { AuditContext, AuditService } from '../../../infrastructure/audit/audit.service';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';

@Injectable()
export class PatchSupportThreadUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
  ) {}

  async execute(id: string, body: unknown, ctx: AuditContext) {
    const input = patchSupportThreadSchema.parse(body);
    const updated = await this.prisma.supportThread.update({
      where: { id },
      data: { status: input.status },
    });
    await this.audit.record(ctx, {
      action: AuditAction.SUPPORT_THREAD_UPDATE,
      targetType: 'support_thread',
      targetId: id,
      after: { status: input.status },
    });
    return updated;
  }
}
