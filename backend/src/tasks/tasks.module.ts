import { Module } from '@nestjs/common';
import { AutomationModule } from '../automation/automation.module'; import { TasksController } from './tasks.controller'; import { TasksService } from './tasks.service'; @Module({imports:[AutomationModule],controllers:[TasksController],providers:[TasksService]}) export class TasksModule {}
