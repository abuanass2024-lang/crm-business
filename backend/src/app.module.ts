import { Module } from '@nestjs/common';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { APP_GUARD } from '@nestjs/core';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { DashboardModule } from './dashboard/dashboard.module';
import { HealthController } from './health.controller';
import { CustomersModule } from './customers/customers.module';
import { OpportunitiesModule } from './opportunities/opportunities.module';
import { TasksModule } from './tasks/tasks.module';
import { ActivitiesModule } from './activities/activities.module';
import { NotificationsModule } from './notifications/notifications.module';
import { UsersModule } from './users/users.module';
import { AutomationModule } from './automation/automation.module';
import { AuditModule } from './audit/audit.module';
import { AnalyticsModule } from './analytics/analytics.module';
import { SubscriptionsModule } from './subscriptions/subscriptions.module';
import { PlatformAdminModule } from './platform-admin/platform-admin.module';
@Module({
 imports:[
  ThrottlerModule.forRoot([{ttl:60000,limit:120}]), PrismaModule, AuthModule, DashboardModule, CustomersModule, OpportunitiesModule, TasksModule, ActivitiesModule, NotificationsModule, UsersModule, AutomationModule, AuditModule, AnalyticsModule, SubscriptionsModule, PlatformAdminModule
 ],
 controllers:[HealthController],
 providers:[{provide:APP_GUARD,useClass:ThrottlerGuard}]
}) export class AppModule {}
