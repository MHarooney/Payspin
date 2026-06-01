import { BankAccountSummary } from '@payspin/shared-types';

export class BankAccountsMapper {
  static toSummary(account: {
    id: string;
    ibanLast4: string;
    accountHolder: string;
    bankName: string | null;
    verified: boolean;
    isPrimary: boolean;
    createdAt: Date;
  }): BankAccountSummary {
    return {
      id: account.id,
      ibanLast4: account.ibanLast4,
      accountHolder: account.accountHolder,
      bankName: account.bankName,
      verified: account.verified,
      isPrimary: account.isPrimary,
      createdAt: account.createdAt.toISOString(),
    };
  }
}
