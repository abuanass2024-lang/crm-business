ALTER TABLE "Customer" ADD COLUMN IF NOT EXISTS "branch" TEXT;
CREATE INDEX IF NOT EXISTS "Customer_branch_idx" ON "Customer"("branch");
