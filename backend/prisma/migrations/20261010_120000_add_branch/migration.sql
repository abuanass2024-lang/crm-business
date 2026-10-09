ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "branch" TEXT;
CREATE INDEX IF NOT EXISTS "User_branch_idx" ON "User"("branch");
