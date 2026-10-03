import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { SubscriptionsService } from '../subscriptions/subscriptions.service';
import * as bcrypt from 'bcryptjs';
import { CreateUserDto, UpdateUserDto } from './users.dto';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService, private readonly subscriptions: SubscriptionsService) {}
  list(companyId: string) {
    return this.prisma.user.findMany({ where:{companyId}, select:{id:true,name:true,email:true,role:true,active:true,createdAt:true}, orderBy:{createdAt:'asc'} });
  }
  async create(companyId:string,dto:CreateUserDto){
    await this.subscriptions.assertWithinQuota(companyId, 'users');
    const exists=await this.prisma.user.findFirst({where:{companyId,email:dto.email}});
    if(exists) throw new BadRequestException('Email already exists in this company');
    const passwordHash=await bcrypt.hash(dto.password,12);
    const created=await this.prisma.user.create({data:{companyId,name:dto.name,email:dto.email,passwordHash,role:dto.role},select:{id:true,name:true,email:true,role:true,active:true,createdAt:true}});
    await this.prisma.auditLog.create({data:{companyId,action:'USER_CREATED',entity:'User',entityId:created.id,metadata:{newValue:created}}});
    return created;
  }
  async update(companyId:string,id:string,dto:UpdateUserDto){
    const user=await this.prisma.user.findFirst({where:{id,companyId}});
    if(!user) throw new NotFoundException('User not found');
    if(user.role==='OWNER' && dto.role && dto.role!=='ADMIN') throw new BadRequestException('Owner role cannot be downgraded');
    const updated=await this.prisma.user.update({where:{id},data:dto,select:{id:true,name:true,email:true,role:true,active:true,createdAt:true}});
    await this.prisma.auditLog.create({data:{companyId,action:dto.role?'ROLE_CHANGED':'UPDATE',entity:'User',entityId:id,metadata:{oldValue:{role:user.role,active:user.active,name:user.name},newValue:updated}}});
    return updated;
  }
}
