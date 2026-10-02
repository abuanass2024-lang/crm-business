import { Global, Module } from '@nestjs/common';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { JwtGuard } from './jwt.guard';
import { PermissionGuard } from './permission.guard';
@Global() @Module({controllers:[AuthController],providers:[AuthService,JwtGuard,PermissionGuard],exports:[AuthService,JwtGuard,PermissionGuard]}) export class AuthModule {}
