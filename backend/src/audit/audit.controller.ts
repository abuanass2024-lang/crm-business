import { Controller, Get, Query, Req, UseGuards } from '@nestjs/common';
import { JwtGuard } from '../auth/jwt.guard';
import { PrismaService } from '../prisma/prisma.service';
@Controller('audit-logs') @UseGuards(JwtGuard)
export class AuditController {
 constructor(private prisma:PrismaService){}
 @Get() list(@Req()r:any,@Query('entity')entity?:string,@Query('action')action?:string){return this.prisma.auditLog.findMany({where:{companyId:r.user.companyId,...(entity?{entity}:{}),...(action?{action}:{})},orderBy:{createdAt:'desc'},take:300});}
}
