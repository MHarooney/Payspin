import { Inject, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AIS_GATEWAY, AisGateway } from '@payspin/pisp-provider';
import { connectBankAccountSchema } from '@payspin/validators';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { EncryptionService } from '../../../infrastructure/encryption/encryption.service';
import {
  institutionConfigFromEnv,
  resolveInstitutionForIban,
} from '../../../domain/utils/institution-routing';

export interface ConnectBankAccountResult {
  connectionId: string;
  authorisationUrl: string;
}

@Injectable()
export class ConnectBankAccountUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
    private readonly encryption: EncryptionService,
    @Inject(AIS_GATEWAY) private readonly aisGateway: AisGateway,
  ) {}

  async execute(userId: string, body: unknown): Promise<ConnectBankAccountResult> {
    const parsed = connectBankAccountSchema.parse(body ?? {});
    const apiBase = this.config.get<string>('API_BASE_URL') ?? 'http://localhost:3001';
    const callbackUrl = `${apiBase}/v1/bank-accounts/connect/callback`;

    // When the caller did not pin an institution, derive it from the country of
    // the user's most recent bank account IBAN so DE/NL/GB payees reach the
    // right sandbox instead of a single hardcoded default.
    const institutionId = parsed.institutionId ?? (await this.resolveInstitution(userId));

    const auth = await this.aisGateway.createAccountAuthRequest({
      applicationUserId: userId,
      institutionId,
      callbackUrl,
    });

    await this.prisma.bankConnection.create({
      data: {
        userId,
        institutionId: institutionId ?? 'yapily-mock',
        yapilyAuthId: auth.connectionId,
        status: 'PENDING',
      },
    });

    return {
      connectionId: auth.connectionId,
      authorisationUrl: auth.authorisationUrl,
    };
  }

  /**
   * Best-effort institution resolution from the user's latest bank account
   * IBAN country. Falls back to the configured default when the user has no
   * stored account yet or decryption fails.
   */
  private async resolveInstitution(userId: string): Promise<string | undefined> {
    const config = institutionConfigFromEnv((key) => this.config.get<string>(key));
    const account = await this.prisma.bankAccount.findFirst({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
    if (!account) return config.default;
    try {
      const iban = this.encryption.decrypt(account.ibanEncrypted, account.ibanIv);
      return resolveInstitutionForIban(iban, config).institutionId;
    } catch {
      return config.default;
    }
  }
}
