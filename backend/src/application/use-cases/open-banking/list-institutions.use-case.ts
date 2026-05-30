import { Inject, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AIS_GATEWAY, AisGateway, InstitutionSummary } from '@payspin/pisp-provider';
import { listInstitutionsSchema } from '@payspin/validators';

@Injectable()
export class ListInstitutionsUseCase {
  constructor(
    private readonly config: ConfigService,
    @Inject(AIS_GATEWAY) private readonly aisGateway: AisGateway,
  ) {}

  async execute(country?: string): Promise<InstitutionSummary[]> {
    const parsed = listInstitutionsSchema.parse({ country });
    const resolved =
      parsed.country?.toUpperCase() ??
      this.config.get<string>('YAPILY_DEFAULT_COUNTRY') ??
      'NL';
    return this.aisGateway.listInstitutions(resolved);
  }
}
