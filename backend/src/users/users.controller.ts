import { Body, Controller, Get, Param, Patch, Post, Req, UseGuards } from '@nestjs/common';
import { JwtGuard } from '../auth/jwt.guard';
import { PermissionGuard, RequirePermission } from '../auth/permission.guard';
import { UsersService } from './users.service';
import { CreateUserDto, UpdateUserDto } from './users.dto';

@Controller('users')
@UseGuards(JwtGuard, PermissionGuard)
export class UsersController {
  constructor(private readonly users:UsersService){}
  @Get() @RequirePermission('users.read') list(@Req() req:any){return this.users.list(req.user.companyId);}
  @Post() @RequirePermission('users.manage') create(@Req() req:any,@Body() dto:CreateUserDto){return this.users.create(req.user.companyId,dto);}
  @Patch(':id') @RequirePermission('users.manage') update(@Req() req:any,@Param('id') id:string,@Body() dto:UpdateUserDto){return this.users.update(req.user.companyId,id,dto);}
}
