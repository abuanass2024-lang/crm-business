-- CreateTable TaskComment
CREATE TABLE IF NOT EXISTS "TaskComment" (
  "id" TEXT NOT NULL,
  "taskId" TEXT NOT NULL,
  "userId" TEXT NOT NULL,
  "message" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "TaskComment_pkey" PRIMARY KEY ("id")
);

-- Indexes
CREATE INDEX IF NOT EXISTS "TaskComment_taskId_createdAt_idx" 
  ON "TaskComment"("taskId", "createdAt");

CREATE INDEX IF NOT EXISTS "TaskComment_userId_idx" 
  ON "TaskComment"("userId");

-- Foreign keys
ALTER TABLE "TaskComment" 
  DROP CONSTRAINT IF EXISTS "TaskComment_taskId_fkey";
ALTER TABLE "TaskComment" 
  ADD CONSTRAINT "TaskComment_taskId_fkey" 
  FOREIGN KEY ("taskId") REFERENCES "Task"("id") 
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "TaskComment" 
  DROP CONSTRAINT IF EXISTS "TaskComment_userId_fkey";
ALTER TABLE "TaskComment" 
  ADD CONSTRAINT "TaskComment_userId_fkey" 
  FOREIGN KEY ("userId") REFERENCES "User"("id") 
  ON DELETE CASCADE ON UPDATE CASCADE;
