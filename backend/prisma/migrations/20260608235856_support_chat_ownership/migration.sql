-- AlterTable
ALTER TABLE "support_threads" ADD COLUMN     "category" TEXT,
ADD COLUMN     "context_ref" TEXT,
ADD COLUMN     "user_id" TEXT,
ADD COLUMN     "user_unread" BOOLEAN NOT NULL DEFAULT false;

-- CreateIndex
CREATE INDEX "support_threads_user_id_last_message_at_idx" ON "support_threads"("user_id", "last_message_at");

-- AddForeignKey
ALTER TABLE "support_threads" ADD CONSTRAINT "support_threads_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
