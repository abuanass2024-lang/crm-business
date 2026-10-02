import { Body, Controller, Delete, Get, Param, Patch, Post, Query, Req, UseGuards } from '@nestjs/common';
import { JwtGuard } from '../auth/jwt.guard';
import { CustomersService } from './customers.service';
import { CreateCustomerDto, UpdateCustomerDto } from './customers.dto';

@Controller('customers')
@UseGuards(JwtGuard)
export class CustomersController {
  constructor(private readonly customers: CustomersService) {}
  @Get() list(@Req() req: any, @Query('q') q?: string) { return this.customers.list(req.user.companyId, q); }
  @Post() create(@Req() req: any, @Body() dto: CreateCustomerDto) { return this.customers.create(req.user.companyId, dto); }
  @Get(':id') get(@Req() req: any, @Param('id') id: string) { return this.customers.get(req.user.companyId, id); }
  @Patch(':id') update(@Req() req: any, @Param('id') id: string, @Body() dto: UpdateCustomerDto) { return this.customers.update(req.user.companyId, id, dto); }
  @Delete(':id') remove(@Req() req: any, @Param('id') id: string) { return this.customers.remove(req.user.companyId, id); }
}
