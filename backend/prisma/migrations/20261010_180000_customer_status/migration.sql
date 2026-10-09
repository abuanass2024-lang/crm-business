-- Create CustomerStatus enum
DO $$ BEGIN
  CREATE TYPE "CustomerStatus" AS ENUM ('PROSPECT', 'CUSTOMER', 'ACTIVE', 'INACTIVE', 'WITHDRAWN');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Add new columns
ALTER TABLE "Customer" ADD COLUMN IF NOT EXISTS "firstInteractionAt" TIMESTAMP(3);
ALTER TABLE "Customer" ADD COLUMN IF NOT EXISTS "lastInteractionAt" TIMESTAMP(3);

-- Migrate existing status text values to new enum
-- Convert old string values to new enum safely
ALTER TABLE "Customer" 
  ALTER COLUMN "status" DROP DEFAULT;

-- Change column type from text to CustomerStatus
-- Existing values that don't match become PROSPECT
ALTER TABLE "Customer" 
  ALTER COLUMN "status" TYPE "CustomerStatus" 
  USING (
    CASE 
      WHEN "status" = 'ACTIVE' THEN 'ACTIVE'::"CustomerStatus"
      WHEN "status" = 'INACTIVE' THEN 'INACTIVE'::"CustomerStatus"
      WHEN "status" = 'CUSTOMER' THEN 'CUSTOMER'::"CustomerStatus"
      WHEN "status" = 'PROSPECT' THEN 'PROSPECT'::"CustomerStatus"
      WHEN "status" = 'WITHDRAWN' THEN 'WITHDRAWN'::"CustomerStatus"
      ELSE 'PROSPECT'::"CustomerStatus"
    END
  );

-- Set default to PROSPECT
ALTER TABLE "Customer" 
  ALTER COLUMN "status" SET DEFAULT 'PROSPECT'::"CustomerStatus";

-- Add index on status
CREATE INDEX IF NOT EXISTS "Customer_companyId_status_idx" ON "Customer"("companyId", "status");
