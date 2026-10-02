import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import * as jwt from 'jsonwebtoken';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class JwtGuard implements CanActivate {
  constructor(private readonly prisma: PrismaService) {}
  async canActivate(ctx: ExecutionContext) {
    const req = ctx.switchToHttp().getRequest();
    const header = req.headers.authorization || '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : '';
    if (!token) throw new UnauthorizedException();
    try {
      const payload:any = jwt.verify(token, process.env.JWT_SECRET || '');
      const user = await this.prisma.user.findFirst({ where: { id: payload.userId || payload.sub, companyId: payload.companyId, active: true }, select: { id:true, companyId:true, role:true, active:true, company:{select:{status:true}} } });
      if (!user) throw new UnauthorizedException('Session is no longer active');
      if (user.company.status !== 'ACTIVE') throw new UnauthorizedException('Company is suspended');
      req.user = { ...payload, userId:user.id, companyId:user.companyId, role:user.role };
      return true;
    } catch {
      throw new UnauthorizedException('Invalid or expired access token');
    }
  }
}
