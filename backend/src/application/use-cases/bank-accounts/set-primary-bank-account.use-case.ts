import { Injectable, NotFoundException } from '@nestjs/common';
import { BankAccountSummary } from '@payspin/shared-types';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { BankAccountsMapper } from './bank-accounts.mapper';

@Injectable()
export class SetPrimaryBankAccountUseCase {
  constructor(private readonly prisma: PrismaService) {}

  async execute(userId: string, accountId: string): Promise<BankAccountSummary> {
    const account = await this.prisma.bankAccount.findFirst({
      where: { id: accountId, userId },
    });
    if (!account) {
      throw new NotFoundException('Bank account not found');
    }

    if (account.isPrimary) {
      return BankAccountsMapper.toSummary(account);
    }

    // Clear the old primary before setting the new one so the per-user
    // "one primary" unique index is never violated mid-transaction.
    const [, updated] = await this.prisma.$transaction([
      this.prisma.bankAccount.updateMany({
        where: { userId, isPrimary: true },
        data: { isPrimary: false },
      }),
      this.prisma.bankAccount.update({
        where: { id: accountId },
        data: { isPrimary: true },
      }),
    ]);

    return BankAccountsMapper.toSummary(updated);
  }
}
