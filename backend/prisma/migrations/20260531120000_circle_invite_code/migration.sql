-- AlterTable
ALTER TABLE "circles" ADD COLUMN "invite_code" TEXT;
ALTER TABLE "circles" ADD COLUMN "started_at" TIMESTAMP(3);

-- Backfill invite codes for any existing rows
UPDATE "circles" SET "invite_code" = substr(md5(random()::text), 1, 8) WHERE "invite_code" IS NULL;

ALTER TABLE "circles" ALTER COLUMN "invite_code" SET NOT NULL;

-- CreateIndex
CREATE UNIQUE INDEX "circles_invite_code_key" ON "circles"("invite_code");
CREATE INDEX "circles_host_user_id_idx" ON "circles"("host_user_id");

-- CreateIndex
CREATE UNIQUE INDEX "circle_members_circle_id_user_id_key" ON "circle_members"("circle_id", "user_id");
CREATE INDEX "circle_members_user_id_idx" ON "circle_members"("user_id");
