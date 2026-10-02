import { CanActivate, ExecutionContext, ForbiddenException, Injectable, SetMetadata } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { PrismaService } from '../prisma/prisma.service';

export const PERMISSION_KEY='required_permission';
export const RequirePermission=(permission:string)=>SetMetadata(PERMISSION_KEY,permission);

@Injectable()
export class PermissionGuard implements CanActivate {
  constructor(private reflector:Reflector,private prisma:PrismaService){}
  async canActivate(ctx:ExecutionContext){
    const required=this.reflector.getAllAndOverride<string>(PERMISSION_KEY,[ctx.getHandler(),ctx.getClass()]);
    if(!required) return true;
    const req=ctx.switchToHttp().getRequest();
    const role=req.user?.role;
    if(role==='OWNER') return true;
    const found=await this.prisma.rolePermission.findUnique({where:{role_permission:{role,permission:required}}});
    if(!found) throw new ForbiddenException('Permission denied');
    return true;
  }
}
