-- Store Yapily consent for payment-status polling (required by GET /payments/{id}/details).
ALTER TABLE "payments" ADD COLUMN "yapily_consent_token" TEXT;
