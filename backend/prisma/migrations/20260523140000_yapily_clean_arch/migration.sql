-- AlterEnum
ALTER TYPE "PaymentStatus" ADD VALUE IF NOT EXISTS 'AWAITING_AUTHORIZATION' BEFORE 'PENDING';

-- AlterTable
ALTER TABLE "bank_accounts" ADD COLUMN IF NOT EXISTS "verification_source" TEXT;
ALTER TABLE "bank_accounts" ADD COLUMN IF NOT EXISTS "yapily_connection_id" TEXT;
ALTER TABLE "bank_accounts" ADD COLUMN IF NOT EXISTS "yapily_institution_id" TEXT;

-- AlterTable
ALTER TABLE "payments" ADD COLUMN IF NOT EXISTS "yapily_auth_request_id" TEXT;
ALTER TABLE "payments" ADD COLUMN IF NOT EXISTS "payment_request_snapshot" JSONB;

-- CreateTable
CREATE TABLE IF NOT EXISTS "bank_connections" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "institution_id" TEXT NOT NULL,
    "yapily_auth_id" TEXT,
    "status" TEXT NOT NULL DEFAULT 'PENDING',
    "bank_account_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "bank_connections_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "bank_connections_user_id_idx" ON "bank_connections"("user_id");

ALTER TABLE "bank_connections" ADD CONSTRAINT "bank_connections_bank_account_id_fkey" FOREIGN KEY ("bank_account_id") REFERENCES "bank_accounts"("id") ON DELETE SET NULL ON UPDATE CASCADE;
