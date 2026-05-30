import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';

@Injectable()
export class GetDefaultBankAccountUseCase {
  constructor(private readonly prisma: PrismaService) {}

  async execute(userId: string) {
    const account = await this.prisma.bankAccount.findFirst({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
    if (!account) {
      throw new BadRequestException('Add a bank account before creating payment links');
    }
    return account;
  }
}
