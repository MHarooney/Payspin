import { Injectable } from '@nestjs/common';
import {
  AccountAuthRequestParams,
  AccountAuthRequestResult,
  AisGateway,
  InstitutionSummary,
  YapilyAccount,
} from '@payspin/pisp-provider';

@Injectable()
export class SandboxAisGateway implements AisGateway {
  async listInstitutions(country: string): Promise<InstitutionSummary[]> {
    return [
      {
        id: 'yapily-mock',
        name: 'Yapily Mock',
        fullName: 'Yapily Mock Bank',
        countries: [{ countryCode2: country.toUpperCase(), displayName: country }],
      },
    ];
  }

  async createAccountAuthRequest(
    params: AccountAuthRequestParams,
  ): Promise<AccountAuthRequestResult> {
    const connectionId = `sandbox_conn_${params.applicationUserId}`;
    return {
      connectionId,
      authorisationUrl: `${params.callbackUrl}?sandboxConnection=${connectionId}`,
    };
  }

  async getAccounts(): Promise<YapilyAccount[]> {
    return [
      {
        id: 'sandbox-account-1',
        type: 'Personal',
        accountNames: [{ name: 'Sandbox User' }],
        accountIdentifications: [
          { type: 'IBAN', identification: 'NL91ABNA0417164300' },
        ],
        institution: { name: 'Yapily Mock' },
      },
    ];
  }
}
