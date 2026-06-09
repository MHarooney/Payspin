import { Injectable, NotFoundException } from '@nestjs/common';
import { SupportThreadWithMessages } from '@payspin/shared-types';
import { createSupportThreadSchema } from '@payspin/validators';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { SupportMapper } from './support.mapper';

@Injectable()
export class CreateSupportThreadUseCase {
  constructor(private readonly prisma: PrismaService) {}

  async execute(userId: string, body: unknown): Promise<SupportThreadWithMessages> {
    const input = createSupportThreadSchema.parse(body);
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');

    const subject =
      input.subject?.trim() ||
      SupportMapper.categoryLabel(input.category) ||
      'Support request';

    const thread = await this.prisma.supportThread.create({
      data: {
        userId,
        userRef: SupportMapper.userRef(user, userId),
        subjectName: subject,
        category: input.category ?? null,
        contextRef: input.contextRef ?? null,
        meta: SupportMapper.buildMeta(user, input.category, input.contextRef),
        status: 'OPEN',
        unread: true,
        userUnread: false,
        lastMessageAt: new Date(),
        messages: {
          create: [
            {
              direction: 'IN',
              authorName: SupportMapper.authorName(user),
              body: input.body,
            },
          ],
        },
      },
      include: { messages: { orderBy: { createdAt: 'asc' } } },
    });

    return SupportMapper.toDetail(thread);
  }
}
