import { Module } from '@nestjs/common';
import { AutomationModule } from '../automation/automation.module';
import { SubscriptionsModule } from '../subscriptions/subscriptions.module';
import { OpportunitiesController } from './opportunities.controller';
import { OpportunitiesService } from './opportunities.service';
@Module({imports:[AutomationModule,SubscriptionsModule],controllers:[OpportunitiesController],providers:[OpportunitiesService]})
export class OpportunitiesModule{}
