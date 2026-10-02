import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class PlatformAdminService {
  constructor(private readonly prisma: PrismaService) {}

  async companies() {
    const rows = await this.prisma.company.findMany({
      orderBy: { createdAt: 'desc' },
      include: { _count: { select: { users:true, customers:true, opportunities:true } }, subscriptions: { include:{ plan:true }, orderBy:{createdAt:'desc'}, take:1 } }
    });
    return rows.map(c => ({ id:c.id, name:c.name, status:c.status, createdAt:c.createdAt, users:c._count.users, customers:c._count.customers, opportunities:c._count.opportunities, subscription:c.subscriptions[0] || null }));
  }

  async setCompanyStatus(companyId:string, status:'ACTIVE'|'SUSPENDED') {
    const company=await this.prisma.company.findUnique({where:{id:companyId},select:{id:true}});
    if(!company) throw new NotFoundException('Company not found');
    return this.prisma.company.update({where:{id:companyId},data:{status},select:{id:true,name:true,status:true,updatedAt:true}});
  }

  async assignPlan(companyId:string, planCode:string, status:'TRIAL'|'ACTIVE'|'PAST_DUE'|'SUSPENDED'|'CANCELLED'='ACTIVE') {
    const [company,plan]=await Promise.all([
      this.prisma.company.findUnique({where:{id:companyId},select:{id:true}}),
      this.prisma.plan.findUnique({where:{code:planCode}})
    ]);
    if(!company) throw new NotFoundException('Company not found');
    if(!plan || !plan.active) throw new BadRequestException('Plan not found or inactive');
    const current=await this.prisma.subscription.findFirst({where:{companyId,status:{in:['TRIAL','ACTIVE','PAST_DUE','SUSPENDED']}},orderBy:{createdAt:'desc'}});
    if(current) return this.prisma.subscription.update({where:{id:current.id},data:{planId:plan.id,status},include:{plan:true}});
    return this.prisma.subscription.create({data:{companyId,planId:plan.id,status},include:{plan:true}});
  }

  async stats(){
    const [companies,activeCompanies,users,customers,opportunities]=await Promise.all([
      this.prisma.company.count(), this.prisma.company.count({where:{status:'ACTIVE'}}), this.prisma.user.count({where:{active:true}}), this.prisma.customer.count(), this.prisma.opportunity.count()
    ]);
    return {companies,activeCompanies,suspendedCompanies:companies-activeCompanies,activeUsers:users,customers,opportunities};
  }
}
