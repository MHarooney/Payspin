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
    const { ciphertext, iv } = this.encryption.encrypt(parsed.iban);

    const account = await this.prisma.bankAccount.create({
      data: {
        userId,
        ibanEncrypted: ciphertext,
        ibanIv: iv,
        ibanLast4: ibanLast4(parsed.iban),
        accountHolder: parsed.accountHolder,
        bankName: parsed.bankName ?? null,
        verificationSource: 'MANUAL',
      },
    });
    return BankAccountsMapper.toSummary(account);
  }
}
