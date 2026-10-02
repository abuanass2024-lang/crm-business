import { Module } from '@nestjs/common';
import { PlatformAdminController } from './platform-admin.controller';
import { PlatformAdminService } from './platform-admin.service';
import { PlatformAdminGuard } from '../platform-admin.guard';
@Module({ controllers:[PlatformAdminController], providers:[PlatformAdminService, PlatformAdminGuard], exports:[PlatformAdminGuard] })
export class PlatformAdminModule {}
