import { Body, Controller, Get, Param, Patch, Post, Req, UseGuards } from '@nestjs/common';
import { JwtGuard } from '../auth/jwt.guard';
import { PlatformAdminGuard } from '../platform-admin.guard';
import { PlatformAdminService } from './platform-admin.service';
import { AssignPlanDto, CompanyStatusDto } from './platform-admin.dto';
@Controller('platform-admin')
@UseGuards(JwtGuard, PlatformAdminGuard)
export class PlatformAdminController {
  constructor(private readonly service:PlatformAdminService){}
  @Get('stats') stats(){ return this.service.stats(); }
  @Get('companies') companies(){ return this.service.companies(); }
  @Patch('companies/:id/status') setStatus(@Param('id') id:string,@Body() dto:CompanyStatusDto,@Req() req:any){ return this.service.setCompanyStatus(id,dto.status); }
  @Post('companies/:id/plan') assignPlan(@Param('id') id:string,@Body() dto:AssignPlanDto){ return this.service.assignPlan(id,dto.planCode,dto.status || 'ACTIVE'); }
}
