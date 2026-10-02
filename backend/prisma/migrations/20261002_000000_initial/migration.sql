CREATE TYPE "UserRole" AS ENUM ('OWNER','ADMIN','MANAGER','SALES','VIEWER');
CREATE TYPE "CompanyStatus" AS ENUM ('ACTIVE','SUSPENDED');
CREATE TYPE "OpportunityStage" AS ENUM ('LEAD','QUALIFIED','MEETING','PROPOSAL','NEGOTIATION','WON','LOST');
CREATE TYPE "TaskStatus" AS ENUM ('TODO','IN_PROGRESS','COMPLETED','CANCELLED');
CREATE TYPE "TaskPriority" AS ENUM ('LOW','MEDIUM','HIGH','URGENT');
CREATE TYPE "AutomationTrigger" AS ENUM ('CUSTOMER_CREATED','OPPORTUNITY_CREATED','OPPORTUNITY_STAGE_CHANGED','TASK_CREATED','TASK_DUE_SOON','TASK_OVERDUE','OPPORTUNITY_WON','OPPORTUNITY_LOST');
CREATE TYPE "AutomationAction" AS ENUM ('CREATE_TASK','CREATE_NOTIFICATION','CHANGE_CUSTOMER_STATUS','LOG_ACTIVITY');
CREATE TYPE "SubscriptionStatus" AS ENUM ('TRIAL','ACTIVE','PAST_DUE','SUSPENDED','CANCELLED');

CREATE TABLE "Company" (
 "id" TEXT NOT NULL, "name" TEXT NOT NULL, "country" TEXT DEFAULT 'YE', "currency" TEXT DEFAULT 'YER', "status" "CompanyStatus" NOT NULL DEFAULT 'ACTIVE', "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, "updatedAt" TIMESTAMP(3) NOT NULL,
 CONSTRAINT "Company_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "User" (
 "id" TEXT NOT NULL, "companyId" TEXT NOT NULL, "name" TEXT NOT NULL, "email" TEXT NOT NULL, "passwordHash" TEXT NOT NULL, "role" "UserRole" NOT NULL DEFAULT 'SALES', "active" BOOLEAN NOT NULL DEFAULT true, "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "Customer" (
 "id" TEXT NOT NULL, "companyId" TEXT NOT NULL, "name" TEXT NOT NULL, "companyName" TEXT, "phone" TEXT, "email" TEXT, "address" TEXT, "status" TEXT NOT NULL DEFAULT 'ACTIVE', "assignedTo" TEXT, "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, "updatedAt" TIMESTAMP(3) NOT NULL,
 CONSTRAINT "Customer_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "Opportunity" (
 "id" TEXT NOT NULL, "companyId" TEXT NOT NULL, "customerId" TEXT NOT NULL, "title" TEXT NOT NULL, "value" DECIMAL(18,2) NOT NULL, "currency" TEXT NOT NULL DEFAULT 'YER', "stage" "OpportunityStage" NOT NULL DEFAULT 'LEAD', "probability" INTEGER NOT NULL DEFAULT 10, "expectedCloseDate" TIMESTAMP(3), "assignedTo" TEXT, "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, "updatedAt" TIMESTAMP(3) NOT NULL,
 CONSTRAINT "Opportunity_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "OpportunityStageHistory" (
 "id" TEXT NOT NULL, "companyId" TEXT NOT NULL, "opportunityId" TEXT NOT NULL, "fromStage" "OpportunityStage", "toStage" "OpportunityStage" NOT NULL, "changedBy" TEXT, "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT "OpportunityStageHistory_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "Task" (
 "id" TEXT NOT NULL, "companyId" TEXT NOT NULL, "title" TEXT NOT NULL, "description" TEXT, "customerId" TEXT, "opportunityId" TEXT, "assignedTo" TEXT, "dueDate" TIMESTAMP(3), "status" "TaskStatus" NOT NULL DEFAULT 'TODO', "priority" "TaskPriority" NOT NULL DEFAULT 'MEDIUM', "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, "updatedAt" TIMESTAMP(3) NOT NULL,
 CONSTRAINT "Task_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "Activity" (
 "id" TEXT NOT NULL, "companyId" TEXT NOT NULL, "userId" TEXT NOT NULL, "customerId" TEXT, "opportunityId" TEXT, "type" TEXT NOT NULL, "description" TEXT NOT NULL, "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT "Activity_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "Notification" (
 "id" TEXT NOT NULL, "companyId" TEXT NOT NULL, "userId" TEXT NOT NULL, "type" TEXT NOT NULL, "title" TEXT NOT NULL, "message" TEXT NOT NULL, "referenceType" TEXT, "referenceId" TEXT, "isRead" BOOLEAN NOT NULL DEFAULT false, "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT "Notification_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "AuditLog" (
 "id" TEXT NOT NULL, "companyId" TEXT NOT NULL, "userId" TEXT, "action" TEXT NOT NULL, "entity" TEXT NOT NULL, "entityId" TEXT, "metadata" JSONB, "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT "AuditLog_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "AutomationRule" (
 "id" TEXT NOT NULL, "companyId" TEXT NOT NULL, "name" TEXT NOT NULL, "description" TEXT, "enabled" BOOLEAN NOT NULL DEFAULT true, "trigger" "AutomationTrigger" NOT NULL, "condition" JSONB, "action" "AutomationAction" NOT NULL, "actionData" JSONB, "createdBy" TEXT, "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, "updatedAt" TIMESTAMP(3) NOT NULL,
 CONSTRAINT "AutomationRule_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "AutomationExecution" (
 "id" TEXT NOT NULL, "companyId" TEXT NOT NULL, "ruleId" TEXT NOT NULL, "executionKey" TEXT NOT NULL, "trigger" "AutomationTrigger" NOT NULL, "status" TEXT NOT NULL DEFAULT 'SUCCESS', "context" JSONB, "result" JSONB, "error" TEXT, "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT "AutomationExecution_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "Plan" (
 "id" TEXT NOT NULL, "code" TEXT NOT NULL, "name" TEXT NOT NULL, "description" TEXT, "monthlyPrice" DECIMAL(18,2) NOT NULL DEFAULT 0, "annualPrice" DECIMAL(18,2) NOT NULL DEFAULT 0, "maxUsers" INTEGER NOT NULL DEFAULT 5, "maxCustomers" INTEGER NOT NULL DEFAULT 1000, "maxOpportunities" INTEGER NOT NULL DEFAULT 1000, "active" BOOLEAN NOT NULL DEFAULT true, "sortOrder" INTEGER NOT NULL DEFAULT 0, "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, "updatedAt" TIMESTAMP(3) NOT NULL,
 CONSTRAINT "Plan_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "Subscription" (
 "id" TEXT NOT NULL, "companyId" TEXT NOT NULL, "planId" TEXT NOT NULL, "status" "SubscriptionStatus" NOT NULL DEFAULT 'TRIAL', "startDate" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, "endDate" TIMESTAMP(3), "trialEnd" TIMESTAMP(3), "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, "updatedAt" TIMESTAMP(3) NOT NULL,
 CONSTRAINT "Subscription_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "RolePermission" (
 "id" TEXT NOT NULL, "role" "UserRole" NOT NULL, "permission" TEXT NOT NULL, "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT "RolePermission_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "UserSession" (
 "id" TEXT NOT NULL, "userId" TEXT NOT NULL, "companyId" TEXT NOT NULL, "refreshTokenHash" TEXT NOT NULL, "expiresAt" TIMESTAMP(3) NOT NULL, "revokedAt" TIMESTAMP(3), "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT "UserSession_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "PlatformAdmin" (
 "id" TEXT NOT NULL, "userId" TEXT NOT NULL, "companyId" TEXT NOT NULL, "active" BOOLEAN NOT NULL DEFAULT true, "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT "PlatformAdmin_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "User_companyId_email_key" ON "User"("companyId","email");
CREATE INDEX "User_companyId_idx" ON "User"("companyId");
CREATE INDEX "Customer_companyId_createdAt_idx" ON "Customer"("companyId","createdAt");
CREATE INDEX "Opportunity_companyId_stage_idx" ON "Opportunity"("companyId","stage");
CREATE INDEX "OpportunityStageHistory_companyId_opportunityId_createdAt_idx" ON "OpportunityStageHistory"("companyId","opportunityId","createdAt");
CREATE INDEX "Task_companyId_status_idx" ON "Task"("companyId","status");
CREATE INDEX "Task_companyId_dueDate_idx" ON "Task"("companyId","dueDate");
CREATE INDEX "Activity_companyId_createdAt_idx" ON "Activity"("companyId","createdAt");
CREATE INDEX "Notification_companyId_userId_isRead_createdAt_idx" ON "Notification"("companyId","userId","isRead","createdAt");
CREATE INDEX "AuditLog_companyId_createdAt_idx" ON "AuditLog"("companyId","createdAt");
CREATE INDEX "AuditLog_companyId_entity_entityId_idx" ON "AuditLog"("companyId","entity","entityId");
CREATE INDEX "AutomationRule_companyId_enabled_trigger_idx" ON "AutomationRule"("companyId","enabled","trigger");
CREATE UNIQUE INDEX "AutomationExecution_ruleId_executionKey_key" ON "AutomationExecution"("ruleId","executionKey");
CREATE INDEX "AutomationExecution_companyId_createdAt_idx" ON "AutomationExecution"("companyId","createdAt");
CREATE UNIQUE INDEX "Plan_code_key" ON "Plan"("code");
CREATE INDEX "Subscription_companyId_status_idx" ON "Subscription"("companyId","status");
CREATE INDEX "Subscription_planId_idx" ON "Subscription"("planId");
CREATE UNIQUE INDEX "RolePermission_role_permission_key" ON "RolePermission"("role","permission");
CREATE INDEX "RolePermission_role_idx" ON "RolePermission"("role");
CREATE UNIQUE INDEX "UserSession_refreshTokenHash_key" ON "UserSession"("refreshTokenHash");
CREATE INDEX "UserSession_companyId_userId_idx" ON "UserSession"("companyId","userId");
CREATE INDEX "UserSession_expiresAt_idx" ON "UserSession"("expiresAt");
CREATE UNIQUE INDEX "PlatformAdmin_userId_key" ON "PlatformAdmin"("userId");
CREATE INDEX "PlatformAdmin_companyId_active_idx" ON "PlatformAdmin"("companyId","active");

ALTER TABLE "User" ADD CONSTRAINT "User_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES "Company"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Customer" ADD CONSTRAINT "Customer_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES "Company"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Opportunity" ADD CONSTRAINT "Opportunity_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES "Company"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Opportunity" ADD CONSTRAINT "Opportunity_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "Customer"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "OpportunityStageHistory" ADD CONSTRAINT "OpportunityStageHistory_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES "Company"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "OpportunityStageHistory" ADD CONSTRAINT "OpportunityStageHistory_opportunityId_fkey" FOREIGN KEY ("opportunityId") REFERENCES "Opportunity"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Task" ADD CONSTRAINT "Task_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES "Company"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Task" ADD CONSTRAINT "Task_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "Customer"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "Task" ADD CONSTRAINT "Task_opportunityId_fkey" FOREIGN KEY ("opportunityId") REFERENCES "Opportunity"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "Task" ADD CONSTRAINT "Task_assignedTo_fkey" FOREIGN KEY ("assignedTo") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "Activity" ADD CONSTRAINT "Activity_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES "Company"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Activity" ADD CONSTRAINT "Activity_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Activity" ADD CONSTRAINT "Activity_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "Customer"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "Activity" ADD CONSTRAINT "Activity_opportunityId_fkey" FOREIGN KEY ("opportunityId") REFERENCES "Opportunity"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "Notification" ADD CONSTRAINT "Notification_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES "Company"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Notification" ADD CONSTRAINT "Notification_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "AuditLog" ADD CONSTRAINT "AuditLog_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES "Company"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "AutomationRule" ADD CONSTRAINT "AutomationRule_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES "Company"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "AutomationExecution" ADD CONSTRAINT "AutomationExecution_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES "Company"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "AutomationExecution" ADD CONSTRAINT "AutomationExecution_ruleId_fkey" FOREIGN KEY ("ruleId") REFERENCES "AutomationRule"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Subscription" ADD CONSTRAINT "Subscription_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES "Company"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Subscription" ADD CONSTRAINT "Subscription_planId_fkey" FOREIGN KEY ("planId") REFERENCES "Plan"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "UserSession" ADD CONSTRAINT "UserSession_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "UserSession" ADD CONSTRAINT "UserSession_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES "Company"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "PlatformAdmin" ADD CONSTRAINT "PlatformAdmin_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "PlatformAdmin" ADD CONSTRAINT "PlatformAdmin_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES "Company"("id") ON DELETE CASCADE ON UPDATE CASCADE;
