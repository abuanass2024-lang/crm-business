import { Body, Controller, Delete, Get, Param, Patch, Post, Query, Req, UseGuards } from '@nestjs/common';
import { JwtGuard } from '../auth/jwt.guard';
import { PermissionGuard, RequirePermission } from '../auth/permission.guard';
import { CreateOpportunityDto, UpdateOpportunityDto } from './opportunities.dto';
import { OpportunitiesService } from './opportunities.service';
@Controller('opportunities')
@UseGuards(JwtGuard, PermissionGuard)
export class OpportunitiesController {
  constructor(private readonly service: OpportunitiesService) {}
  @Get()
  @RequirePermission('opportunities.read')
  list(@Req() req:any, @Query('stage') stage?: any) { return this.service.list(req.user.companyId, stage); }
  @Get('pipeline')
  @RequirePermission('opportunities.read')
  pipeline(@Req() req:any) { return this.service.pipeline(req.user.companyId); }
  @Get(':id')
  @RequirePermission('opportunities.read')
  get(@Req() req:any, @Param('id') id:string) { return this.service.get(req.user.companyId, id); }
  @Post()
  @RequirePermission('opportunities.create')
  create(@Req() req:any, @Body() dto:CreateOpportunityDto) { return this.service.create(req.user.companyId, req.user.userId, dto); }
  @Patch(':id')
  @RequirePermission('opportunities.update')
  update(@Req() req:any, @Param('id') id:string, @Body() dto:UpdateOpportunityDto) { return this.service.update(req.user.companyId, req.user.userId, id, dto); }
  @Delete(':id')
  @RequirePermission('opportunities.delete')
  remove(@Req() req:any, @Param('id') id:string) { return this.service.remove(req.user.companyId, id); }
}
