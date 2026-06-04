import { Injectable } from '@nestjs/common';
import { BankAccountSummary } from '@payspin/shared-types';
import { createBankAccountSchema } from '@payspin/validators';
import { ibanLast4 } from '../../../domain/utils/short-code';
import { EncryptionService } from '../../../infrastructure/encryption/encryption.service';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { BankAccountsMapper } from './bank-accounts.mapper';

@Injectable()
export class CreateBankAccountUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly encryption: EncryptionService,
  ) {}

  async execute(userId: string, body: unknown): Promise<BankAccountSummary> {
    const parsed = createBankAccountSchema.parse(body);

    // Idempotent on (user, IBAN): re-adding the same IBAN (e.g. an onboarding
    // retry or re-run) returns the existing account instead of inserting a
    // duplicate. IBANs are encrypted with a random IV so we can't match on
    // ciphertext — decrypt the user's accounts and compare the normalized value.
    const userAccounts = await this.prisma.bankAccount.findMany({ where: { userId } });
    const duplicate = userAccounts.find(
      (a) => this.encryption.decrypt(a.ibanEncrypted, a.ibanIv) === parsed.iban,
    );
    if (duplicate) {
      return BankAccountsMapper.toSummary(duplicate);
    }

    const { ciphertext, iv } = this.encryption.encrypt(parsed.iban);

    // The very first account a user adds becomes their primary; later additions
    // don't displace an existing primary (the user switches it explicitly).
    const existingCount = userAccounts.length;

    const account = await this.prisma.bankAccount.create({
      data: {
        userId,
        ibanEncrypted: ciphertext,
        ibanIv: iv,
        ibanLast4: ibanLast4(parsed.iban),
        accountHolder: parsed.accountHolder,
        bankName: parsed.bankName ?? null,
        isPrimary: existingCount === 0,
        verificationSource: 'MANUAL',
      },
    });
    return BankAccountsMapper.toSummary(account);
  }
}
