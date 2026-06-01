import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';

@Injectable()
export class DeleteBankAccountUseCase {
  constructor(private readonly prisma: PrismaService) {}

  async execute(userId: string, accountId: string): Promise<void> {
    const account = await this.prisma.bankAccount.findFirst({
      where: { id: accountId, userId },
    });
    if (!account) {
      throw new NotFoundException('Bank account not found');
    }

    // Payment links keep an immutable reference to the account they were
    // created with, so an account that has links cannot be removed without
    // orphaning historical/active links.
    const linkCount = await this.prisma.paymentLink.count({
      where: { bankAccountId: accountId },
    });
    if (linkCount > 0) {
      throw new ConflictException(
        'This IBAN is used by existing payment links and cannot be removed',
      );
    }

    await this.prisma.$transaction(async (tx) => {
      // Detach any pending/aborted open-banking connections that point here so
      // the foreign key doesn't block deletion.
      await tx.bankConnection.updateMany({
        where: { bankAccountId: accountId },
        data: { bankAccountId: null },
      });

      await tx.bankAccount.delete({ where: { id: accountId } });

      // If we removed the primary, promote the next most-recent account so the
      // user always has a sensible default for new links.
      if (account.isPrimary) {
        const next = await tx.bankAccount.findFirst({
          where: { userId },
          orderBy: { createdAt: 'desc' },
        });
        if (next) {
          await tx.bankAccount.update({
            where: { id: next.id },
            data: { isPrimary: true },
          });
        }
      }
    });
  }
}
