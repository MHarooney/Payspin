import { ibanCountry } from '@payspin/validators';

export interface InstitutionConfig {
  /** IBAN country (ISO 3166-1 alpha-2) → Yapily institution id. */
  byCountry: Record<string, string | undefined>;
  /** Fallback institution when the country is unknown or unmapped. */
  default: string;
}

export interface InstitutionResolution {
  /** Detected IBAN country, or null when the IBAN was absent/unparseable. */
  country: string | null;
  /** Yapily institution id to use for the auth request. */
  institutionId: string;
}

/**
 * Pick a Yapily institution for an IBAN. The country is derived from the IBAN
 * prefix and mapped via {@link InstitutionConfig.byCountry}; anything unmapped
 * falls back to {@link InstitutionConfig.default} so the flow never breaks.
 */
export function resolveInstitutionForIban(
  iban: string | null | undefined,
  config: InstitutionConfig,
): InstitutionResolution {
  const country = iban ? ibanCountry(iban) : null;
  const mapped = country ? config.byCountry[country] : undefined;
  return { country, institutionId: mapped ?? config.default };
}

/**
 * Build an {@link InstitutionConfig} from env vars. `get` is a plain accessor
 * (e.g. `ConfigService.get`) so this stays framework-agnostic and testable.
 */
export function institutionConfigFromEnv(
  get: (key: string) => string | undefined,
): InstitutionConfig {
  return {
    byCountry: {
      NL: get('YAPILY_INSTITUTION_NL'),
      DE: get('YAPILY_INSTITUTION_DE'),
      GB: get('YAPILY_INSTITUTION_GB'),
    },
    default: get('YAPILY_DEFAULT_INSTITUTION') ?? 'modelo-sandbox',
  };
}
