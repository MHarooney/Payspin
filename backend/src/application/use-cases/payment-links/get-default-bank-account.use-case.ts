import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';

@Injectable()
export class GetDefaultBankAccountUseCase {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * The account a new link pays into when the caller doesn't specify one:
   * the user's primary account, falling back to the most recent.
   */
  async execute(userId: string) {
    const account = await this.prisma.bankAccount.findFirst({
      where: { userId },
      orderBy: [{ isPrimary: 'desc' }, { createdAt: 'desc' }],
    });
    if (!account) {
      throw new BadRequestException('Add a bank account before creating payment links');
    }
    return account;
  }
}
