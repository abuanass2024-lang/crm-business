-- CRM Business v1.4 SaaS platform administration
CREATE TYPE "CompanyStatus" AS ENUM ('ACTIVE', 'SUSPENDED');
ALTER TABLE "Company" ADD COLUMN "status" "CompanyStatus" NOT NULL DEFAULT 'ACTIVE';
CREATE TABLE "PlatformAdmin" (
  "id" TEXT NOT NULL,
  "userId" TEXT NOT NULL,
  "companyId" TEXT NOT NULL,
  "active" BOOLEAN NOT NULL DEFAULT true,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "PlatformAdmin_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "PlatformAdmin_userId_key" ON "PlatformAdmin"("userId");
CREATE INDEX "PlatformAdmin_companyId_active_idx" ON "PlatformAdmin"("companyId", "active");
ALTER TABLE "PlatformAdmin" ADD CONSTRAINT "PlatformAdmin_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "PlatformAdmin" ADD CONSTRAINT "PlatformAdmin_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES "Company"("id") ON DELETE CASCADE ON UPDATE CASCADE;
