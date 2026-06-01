-- AlterTable: add primary-account flag (default for new payment links)
ALTER TABLE "bank_accounts" ADD COLUMN "is_primary" BOOLEAN NOT NULL DEFAULT false;

-- Backfill: preserve today's behavior (newest account per user was the default)
-- by marking each user's most recent account as primary.
UPDATE "bank_accounts" b
SET "is_primary" = true
FROM (
  SELECT DISTINCT ON ("user_id") "id"
  FROM "bank_accounts"
  ORDER BY "user_id", "created_at" DESC
) newest
WHERE b."id" = newest."id";

-- Enforce at most one primary account per user.
CREATE UNIQUE INDEX "bank_accounts_user_id_primary_key"
  ON "bank_accounts"("user_id")
  WHERE "is_primary";
