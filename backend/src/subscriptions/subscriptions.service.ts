import { ForbiddenException, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
@Injectable() export class SubscriptionsService{
 constructor(private prisma:PrismaService){}
 listPlans(){return this.prisma.plan.findMany({where:{active:true},orderBy:{sortOrder:'asc'}})}
 current(companyId:string){return this.prisma.subscription.findFirst({where:{companyId,status:{in:['TRIAL','ACTIVE','PAST_DUE']}},include:{plan:true},orderBy:{createdAt:'desc'}})}
 async assertWithinQuota(companyId:string, resource:'users'|'customers'|'opportunities'){
   const sub=await this.current(companyId);
   if(sub && sub.endDate && sub.endDate <= new Date()) throw new ForbiddenException('Subscription expired');
   if(sub?.trialEnd && sub.status==='TRIAL' && sub.trialEnd <= new Date()) throw new ForbiddenException('Trial period expired');
   if(!sub) throw new ForbiddenException('No active subscription');
   const limits={users:sub.plan.maxUsers,customers:sub.plan.maxCustomers,opportunities:sub.plan.maxOpportunities};
   const count=resource==='users'?await this.prisma.user.count({where:{companyId,active:true}}):resource==='customers'?await this.prisma.customer.count({where:{companyId}}):await this.prisma.opportunity.count({where:{companyId}});
   if(count>=limits[resource]) throw new ForbiddenException(`${resource} quota exceeded for current plan`);
   return {count,limit:limits[resource]};
 }
}
