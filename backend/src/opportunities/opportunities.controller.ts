import { Body, Controller, Delete, Get, Param, Patch, Post, Query, Req, UseGuards } from '@nestjs/common';
import { JwtGuard } from '../auth/jwt.guard';
import { CreateOpportunityDto, UpdateOpportunityDto } from './opportunities.dto';
import { OpportunitiesService } from './opportunities.service';
@Controller('opportunities')
@UseGuards(JwtGuard)
export class OpportunitiesController {
  constructor(private readonly service: OpportunitiesService) {}
  @Get() list(@Req() req:any, @Query('stage') stage?: any) { return this.service.list(req.user.companyId, stage); }
  @Get('pipeline') pipeline(@Req() req:any) { return this.service.pipeline(req.user.companyId); }
  @Get(':id') get(@Req() req:any, @Param('id') id:string) { return this.service.get(req.user.companyId, id); }
  @Post() create(@Req() req:any, @Body() dto:CreateOpportunityDto) { return this.service.create(req.user.companyId, req.user.userId, dto); }
  @Patch(':id') update(@Req() req:any, @Param('id') id:string, @Body() dto:UpdateOpportunityDto) { return this.service.update(req.user.companyId, req.user.userId, id, dto); }
  @Delete(':id') remove(@Req() req:any, @Param('id') id:string) { return this.service.remove(req.user.companyId, id); }
}
