import { Inject, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AIS_GATEWAY, AisGateway } from '@payspin/pisp-provider';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';

export interface ConnectBankAccountResult {
  connectionId: string;
  authorisationUrl: string;
}

@Injectable()
export class ConnectBankAccountUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
    @Inject(AIS_GATEWAY) private readonly aisGateway: AisGateway,
  ) {}

  async execute(
    userId: string,
    body: { institutionId?: string },
  ): Promise<ConnectBankAccountResult> {
    const apiBase = this.config.get<string>('API_BASE_URL') ?? 'http://localhost:3001';
    const callbackUrl = `${apiBase}/v1/bank-accounts/connect/callback`;

    const auth = await this.aisGateway.createAccountAuthRequest({
      applicationUserId: userId,
      institutionId: body.institutionId,
      callbackUrl,
    });

    await this.prisma.bankConnection.create({
      data: {
        userId,
        institutionId: body.institutionId ?? 'yapily-mock',
        yapilyAuthId: auth.connectionId,
        status: 'PENDING',
      },
    });

    return {
      connectionId: auth.connectionId,
      authorisationUrl: auth.authorisationUrl,
    };
  }
}
