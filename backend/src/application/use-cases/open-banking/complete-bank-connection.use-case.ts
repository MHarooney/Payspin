import { BadRequestException, Inject, Injectable, NotFoundException } from '@nestjs/common';
import { BankAccountSummary } from '@payspin/shared-types';
import { AIS_GATEWAY, AisGateway } from '@payspin/pisp-provider';
import { extractIbanFromAccount, ibanLast4 } from '../../../domain/utils/short-code';
import { EncryptionService } from '../../../infrastructure/encryption/encryption.service';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { BankAccountsMapper } from '../bank-accounts/bank-accounts.mapper';

@Injectable()
export class CompleteBankConnectionUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly encryption: EncryptionService,
    @Inject(AIS_GATEWAY) private readonly aisGateway: AisGateway,
  ) {}

  async execute(
    userId: string,
    body: { connectionId: string; consentToken: string; expectedIban?: string },
  ): Promise<BankAccountSummary> {
    const connection = await this.prisma.bankConnection.findFirst({
      where: { userId, yapilyAuthId: body.connectionId },
    });
    if (!connection) {
      throw new NotFoundException('Bank connection not found');
    }

    const accounts = await this.aisGateway.getAccounts(body.consentToken);
    if (!accounts.length) {
      throw new BadRequestException('No accounts returned from bank');
    }

    let selected = accounts[0];
    if (body.expectedIban) {
      const normalized = body.expectedIban.replace(/\s+/g, '').toUpperCase();
      const match = accounts.find((a) => {
        const iban = extractIbanFromAccount(a);
        return iban?.replace(/\s+/g, '').toUpperCase() === normalized;
      });
      if (match) selected = match;
    }

    const iban = extractIbanFromAccount(selected);
    if (!iban) {
      throw new BadRequestException('Selected account has no IBAN');
    }

    const accountHolder =
      selected.accountNames?.[0]?.name ?? 'Account holder';
    const bankName = selected.institution?.name ?? null;
    const { ciphertext, iv } = this.encryption.encrypt(iban);

    const account = await this.prisma.$transaction(async (tx) => {
      const created = await tx.bankAccount.create({
        data: {
          userId,
          ibanEncrypted: ciphertext,
          ibanIv: iv,
          ibanLast4: ibanLast4(iban),
          accountHolder,
          bankName,
          verified: true,
          verificationSource: 'YAPILY',
          yapilyConnectionId: connection.id,
          yapilyInstitutionId: connection.institutionId,
        },
      });

      await tx.bankConnection.update({
        where: { id: connection.id },
        data: { status: 'COMPLETED', bankAccountId: created.id },
      });

      return created;
    });

    return BankAccountsMapper.toSummary(account);
  }
}
