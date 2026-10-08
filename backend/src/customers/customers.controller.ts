import { Body, Controller, Delete, Get, Param, Patch, Post, Query, Req, UseGuards } from '@nestjs/common';
import { JwtGuard } from '../auth/jwt.guard';
import { PermissionGuard, RequirePermission } from '../auth/permission.guard';
import { CustomersService } from './customers.service';
import { CreateCustomerDto, UpdateCustomerDto } from './customers.dto';

@Controller('customers')
@UseGuards(JwtGuard, PermissionGuard)
export class CustomersController {
  constructor(private readonly customers: CustomersService) {}
  @Get()
  @RequirePermission('customers.read')
  list(@Req() req: any, @Query('q') q?: string) { return this.customers.list(req.user.companyId, q); }
  @Post()
  @RequirePermission('customers.create')
  create(@Req() req: any, @Body() dto: CreateCustomerDto) { return this.customers.create(req.user.companyId, dto); }
  @Get(':id')
  @RequirePermission('customers.read')
  get(@Req() req: any, @Param('id') id: string) { return this.customers.get(req.user.companyId, id); }
  @Patch(':id')
  @RequirePermission('customers.update')
  update(@Req() req: any, @Param('id') id: string, @Body() dto: UpdateCustomerDto) { return this.customers.update(req.user.companyId, id, dto); }
  @Delete(':id')
  @RequirePermission('customers.delete')
  remove(@Req() req: any, @Param('id') id: string) { return this.customers.remove(req.user.companyId, id); }
}
