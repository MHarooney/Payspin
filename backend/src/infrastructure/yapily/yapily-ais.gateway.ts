import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  AccountAuthRequestParams,
  AccountAuthRequestResult,
  AisGateway,
  InstitutionSummary,
  YapilyAccount,
} from '@payspin/pisp-provider';
import { YapilyHttpClient } from './yapily-http.client';

interface YapilyMetaResponse<T> {
  data: T;
}

@Injectable()
export class YapilyAisGateway implements AisGateway {
  constructor(
    private readonly http: YapilyHttpClient,
    private readonly config: ConfigService,
  ) {}

  async listInstitutions(country: string): Promise<InstitutionSummary[]> {
    const res = await this.http.request<YapilyMetaResponse<InstitutionSummary[]>>(
      'GET',
      `/institutions?country=${encodeURIComponent(country)}`,
    );
    return (res.data ?? []).filter((inst) =>
      inst.countries?.some((c) => c.countryCode2 === country.toUpperCase()),
    );
  }

  async createAccountAuthRequest(
    params: AccountAuthRequestParams,
  ): Promise<AccountAuthRequestResult> {
    const institutionId =
      params.institutionId ??
      this.config.get<string>('YAPILY_DEFAULT_INSTITUTION') ??
      'yapily-mock';

    const res = await this.http.request<
      YapilyMetaResponse<{ id: string; authorisationUrl: string }>
    >('POST', '/account-auth-requests', {
      body: {
        applicationUserId: params.applicationUserId,
        institutionId,
        callback: params.callbackUrl,
      },
    });

    return {
      connectionId: res.data.id,
      authorisationUrl: res.data.authorisationUrl,
    };
  }

  async getAccounts(consentToken: string): Promise<YapilyAccount[]> {
    const res = await this.http.request<YapilyMetaResponse<YapilyAccount[]>>(
      'GET',
      '/accounts',
      { headers: { Consent: consentToken } },
    );
    return res.data ?? [];
  }
}
