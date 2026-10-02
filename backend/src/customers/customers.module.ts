import { Module } from '@nestjs/common';
import { AutomationModule } from '../automation/automation.module';
import { SubscriptionsModule } from '../subscriptions/subscriptions.module';
import { CustomersController } from './customers.controller';
import { CustomersService } from './customers.service';
@Module({imports:[AutomationModule,SubscriptionsModule],controllers:[CustomersController],providers:[CustomersService]})
export class CustomersModule{}
