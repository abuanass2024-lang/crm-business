import { BadRequestException, Injectable, UnauthorizedException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import * as bcrypt from 'bcryptjs';
import * as jwt from 'jsonwebtoken';
import { randomBytes, createHash } from 'crypto';

@Injectable()
export class AuthService {
  private secret = process.env.JWT_SECRET || '';
  private accessTtl = process.env.ACCESS_TOKEN_TTL || '15m';
  private refreshDays = Number(process.env.REFRESH_TOKEN_TTL_DAYS || 30);
  constructor(private prisma: PrismaService) {}
  private accessToken(user:any){ return jwt.sign({sub:user.id,userId:user.id,companyId:user.companyId,role:user.role},this.secret,{expiresIn:this.accessTtl as any}); }
  private hashRefresh(token:string){ return createHash('sha256').update(token).digest('hex'); }
  private async issueSession(user:any){
    const refreshToken=randomBytes(48).toString('base64url');
    const expiresAt=new Date(Date.now()+this.refreshDays*86400000);
    await this.prisma.userSession.create({data:{userId:user.id,companyId:user.companyId,refreshTokenHash:this.hashRefresh(refreshToken),expiresAt}});
    return {accessToken:this.accessToken(user),refreshToken};
  }
  async register(dto:any){
    const exists=await this.prisma.user.findFirst({where:{email:dto.email}});
    if(exists) throw new BadRequestException('Email already registered');
    const hash=await bcrypt.hash(dto.password,12);
    const result=await this.prisma.$transaction(async tx=>{
      const company=await tx.company.create({data:{name:dto.companyName}});
      const user=await tx.user.create({data:{companyId:company.id,name:dto.ownerName,email:dto.email,passwordHash:hash,role:'OWNER'}});
      const plan=await tx.plan.findFirst({where:{code:'FREE',active:true}});
      if(plan) await tx.subscription.create({data:{companyId:company.id,planId:plan.id,status:'TRIAL',trialEnd:new Date(Date.now()+14*86400000)}});
      return {company,user};
    });
    const tokens=await this.issueSession(result.user);
    await this.prisma.auditLog.create({data:{companyId:result.company.id,userId:result.user.id,action:'REGISTER',entity:'User',entityId:result.user.id,metadata:{email:result.user.email}}});
    return {...tokens,user:{id:result.user.id,name:result.user.name,email:result.user.email,role:result.user.role},company:{id:result.company.id,name:result.company.name}};
  }
  async login(dto:any){
    const user=await this.prisma.user.findFirst({where:{email:dto.email,active:true},include:{company:true}});
    if(!user || !(await bcrypt.compare(dto.password,user.passwordHash))) throw new UnauthorizedException('Invalid credentials');
    const tokens=await this.issueSession(user);
    await this.prisma.auditLog.create({data:{companyId:user.companyId,userId:user.id,action:'LOGIN',entity:'User',entityId:user.id,metadata:{email:user.email}}});
    return {...tokens,user:{id:user.id,name:user.name,email:user.email,role:user.role},company:{id:user.company.id,name:user.company.name}};
  }
  async refresh(refreshToken:string){
    const session=await this.prisma.userSession.findUnique({where:{refreshTokenHash:this.hashRefresh(refreshToken)},include:{user:true}});
    if(!session || session.revokedAt || session.expiresAt<=new Date() || !session.user.active) throw new UnauthorizedException('Invalid refresh token');
    await this.prisma.userSession.update({where:{id:session.id},data:{revokedAt:new Date()}});
    const tokens=await this.issueSession(session.user);
    return tokens;
  }
  async me(userId:string){
    const user=await this.prisma.user.findUnique({where:{id:userId},include:{company:true}});
    if(!user || !user.active) throw new UnauthorizedException();
    return {user:{id:user.id,name:user.name,email:user.email,role:user.role},company:{id:user.company.id,name:user.company.name}};
  }
  async logout(refreshToken:string){
    await this.prisma.userSession.updateMany({where:{refreshTokenHash:this.hashRefresh(refreshToken),revokedAt:null},data:{revokedAt:new Date()}});
    return {success:true};
  }
}
