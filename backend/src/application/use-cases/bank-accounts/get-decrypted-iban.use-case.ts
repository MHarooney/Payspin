import { Injectable, NotFoundException } from '@nestjs/common';
import { EncryptionService } from '../../../infrastructure/encryption/encryption.service';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';

@Injectable()
export class GetDecryptedIbanUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly encryption: EncryptionService,
  ) {}

  async execute(accountId: string, userId: string): Promise<string> {
    const account = await this.prisma.bankAccount.findFirst({
      where: { id: accountId, userId },
    });
    if (!account) throw new NotFoundException('Bank account not found');
    return this.encryption.decrypt(account.ibanEncrypted, account.ibanIv);
  }
}
