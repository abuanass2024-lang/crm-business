import { Body, Controller, Delete, Get, Param, Patch, Post, Req, UseGuards } from '@nestjs/common';
import { JwtGuard } from '../auth/jwt.guard';
import { AutomationService } from './automation.service';
import { CreateAutomationRuleDto, UpdateAutomationRuleDto } from './automation.dto';
@Controller('automation') @UseGuards(JwtGuard)
export class AutomationController {
 constructor(private service:AutomationService){}
 @Get('rules') rules(@Req()r:any){return this.service.listRules(r.user.companyId)}
 @Post('rules') create(@Req()r:any,@Body()d:CreateAutomationRuleDto){return this.service.createRule(r.user.companyId,r.user.userId,d)}
 @Patch('rules/:id') update(@Req()r:any,@Param('id')id:string,@Body()d:UpdateAutomationRuleDto){return this.service.updateRule(r.user.companyId,r.user.userId,id,d)}
 @Delete('rules/:id') remove(@Req()r:any,@Param('id')id:string){return this.service.removeRule(r.user.companyId,r.user.userId,id)}
 @Get('executions') executions(@Req()r:any){return this.service.listExecutions(r.user.companyId)}
 @Post('run-due') runDue(@Req()r:any){return this.service.runDue(r.user.companyId)}
}
