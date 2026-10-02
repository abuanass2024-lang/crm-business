import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';
import { PrismaService } from './prisma/prisma.service';

@Injectable()
export class PlatformAdminGuard implements CanActivate {
  constructor(private readonly prisma: PrismaService) {}
  async canActivate(ctx: ExecutionContext) {
    const req = ctx.switchToHttp().getRequest();
    const userId = req.user?.userId;
    if (!userId) throw new ForbiddenException('Platform admin access required');
    const admin = await this.prisma.platformAdmin.findFirst({ where: { userId, active: true }, select: { id: true, companyId: true } });
    if (!admin) throw new ForbiddenException('Platform admin access required');
    req.platformAdmin = admin;
    return true;
  }
}
