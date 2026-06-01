import { Injectable } from '@nestjs/common';
import { BankAccountSummary } from '@payspin/shared-types';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { BankAccountsMapper } from './bank-accounts.mapper';

@Injectable()
export class ListBankAccountsUseCase {
  constructor(private readonly prisma: PrismaService) {}

  async execute(userId: string): Promise<BankAccountSummary[]> {
    const accounts = await this.prisma.bankAccount.findMany({
      where: { userId },
      orderBy: [{ isPrimary: 'desc' }, { createdAt: 'desc' }],
    });
    return accounts.map((a) => BankAccountsMapper.toSummary(a));
  }
}
