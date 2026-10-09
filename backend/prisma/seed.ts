import { PrismaClient, UserRole } from '@prisma/client';
import * as bcryptLib from 'bcryptjs';
import { PrismaPg } from '@prisma/adapter-pg';

const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL! });
const prisma = new PrismaClient({ adapter });
const permissions={
 OWNER:['users.read','users.manage','customers.read','customers.create','customers.update','customers.delete','opportunities.read','opportunities.create','opportunities.update','opportunities.delete','tasks.read','tasks.create','tasks.update','tasks.delete','activities.read','activities.create','notifications.read','reports.read'],
 ADMIN:['users.read','users.manage','customers.read','customers.create','customers.update','customers.delete','opportunities.read','opportunities.create','opportunities.update','opportunities.delete','tasks.read','tasks.create','tasks.update','tasks.delete','activities.read','activities.create','notifications.read','reports.read'],
 MANAGER:['users.read','customers.read','customers.create','customers.update','opportunities.read','opportunities.create','opportunities.update','tasks.read','tasks.create','tasks.update','activities.read','activities.create','notifications.read','reports.read'],
 SALES:['customers.read','customers.create','customers.update','opportunities.read','opportunities.create','opportunities.update','tasks.read','tasks.create','tasks.update','activities.read','activities.create','notifications.read'],
 VIEWER:['customers.read','opportunities.read','tasks.read','activities.read','notifications.read']
} as const;
async function main(){
const plans=[['FREE','Free',0,0,3,250,250,1],['BASIC','Basic',10,100,10,2500,2500,2],['PROFESSIONAL','Professional',25,250,25,10000,10000,3],['ENTERPRISE','Enterprise',0,0,999999,999999,999999,4]] as const;
for(const [code,name,monthlyPrice,annualPrice,maxUsers,maxCustomers,maxOpportunities,sortOrder] of plans){await prisma.plan.upsert({where:{code},update:{name,monthlyPrice,annualPrice,maxUsers,maxCustomers,maxOpportunities,sortOrder,active:true},create:{code,name,monthlyPrice,annualPrice,maxUsers,maxCustomers,maxOpportunities,sortOrder}})}
for(const [role,list] of Object.entries(permissions)){for(const permission of list){await prisma.rolePermission.upsert({where:{role_permission:{role:role as UserRole,permission}},update:{},create:{role:role as UserRole,permission}})}} const company=await prisma.company.findFirst(); if(company){ const owner=await prisma.user.findFirst({where:{companyId:company.id,role:'OWNER'}}); if(owner){ const plan=await prisma.plan.findUnique({where:{code:'FREE'}}); if(plan){await prisma.subscription.upsert({where:{id:'demo-subscription'},update:{},create:{id:'demo-subscription',companyId:company.id,planId:plan.id,status:'TRIAL',trialEnd:new Date(Date.now()+14*86400000)}})} await prisma.automationRule.upsert({where:{id:'demo-proposal-followup'},update:{},create:{id:'demo-proposal-followup',companyId:company.id,name:'متابعة العرض تلقائياً',description:'إنشاء مهمة بعد انتقال الفرصة إلى مرحلة العرض',trigger:'OPPORTUNITY_STAGE_CHANGED',condition:{toStage:'PROPOSAL'},action:'CREATE_TASK',actionData:{title:'متابعة العرض',priority:'HIGH',dueInDays:2},createdBy:owner.id}}); } }}

async function seedDemoUsers() {
  const company = await prisma.company.findFirst();
  if (!company) { console.log('No company yet, skipping demo users'); return; }
  const hash = await bcryptLib.hash('123456', 12);
  const demoUsers = [
    { empId: 'GM001', name: 'المدير العام', role: 'GENERAL_MANAGER' },
    { empId: 'RM001', name: 'مدير الفروع', role: 'REGIONAL_MANAGER' },
    { empId: 'BM001', name: 'مدير الفرع', role: 'BRANCH_MANAGER' },
    { empId: 'HM001', name: 'مدير القاعة', role: 'HALL_MANAGER' },
    { empId: 'CS001', name: 'خدمة العملاء 1', role: 'CUSTOMER_SERVICE' },
    { empId: 'CS002', name: 'خدمة العملاء 2', role: 'CUSTOMER_SERVICE' },
  ];
  for (const u of demoUsers) {
    await prisma.user.upsert({
      where: { companyId_employeeId: { companyId: company.id, employeeId: u.empId } },
      update: { name: u.name },
      create: {
        companyId: company.id,
        employeeId: u.empId,
        name: u.name,
        email: u.empId.toLowerCase() + '@crm.local',
        passwordHash: hash,
        role: u.role as any,
      },
    });
  }
  console.log('OK Seeded demo users GM001/RM001/BM001/HM001/CS001/CS002 (pwd 123456)');
}

main().then(seedDemoUsers).finally(()=>prisma.$disconnect());
