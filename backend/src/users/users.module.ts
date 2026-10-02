import { Module } from '@nestjs/common';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';
import { PrismaModule } from '../prisma/prisma.module';
import { SubscriptionsModule } from '../subscriptions/subscriptions.module';
@Module({imports:[PrismaModule,SubscriptionsModule],controllers:[UsersController],providers:[UsersService]})
export class UsersModule{}
