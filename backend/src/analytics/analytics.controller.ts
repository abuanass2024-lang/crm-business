import { Controller, Get, Req, UseGuards } from '@nestjs/common';
import { JwtGuard } from '../auth/jwt.guard';
import { AnalyticsService } from './analytics.service';

@Controller('analytics')
@UseGuards(JwtGuard)
export class AnalyticsController {
  constructor(private service: AnalyticsService) {}

  @Get('dashboard')
  dashboard(@Req() r: any) { return this.service.dashboard(r.user.companyId); }

  @Get('pipeline')
  pipeline(@Req() r: any) { return this.service.pipeline(r.user.companyId); }

  @Get('employees')
  employees(@Req() r: any) { return this.service.employees(r.user.companyId); }

  @Get('tasks')
  tasks(@Req() r: any) { return this.service.tasks(r.user.companyId); }

  @Get('customers/report')
  customersReport(@Req() r: any) { return this.service.customersReport(r.user.companyId); }

  @Get('tasks/report')
  tasksReport(@Req() r: any) { return this.service.tasksReport(r.user.companyId); }

  @Get('opportunities/report')
  opportunitiesReport(@Req() r: any) { return this.service.opportunitiesReport(r.user.companyId); }
}
