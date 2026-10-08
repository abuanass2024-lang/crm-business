import * as fs from 'fs';
import * as path from 'path';

const root = process.cwd();

function read(file: string): string {
  return fs.readFileSync(path.join(root, file), 'utf8');
}

function check(name: string, condition: boolean) {
  if (condition) {
    console.log(`PASS: ${name}`);
    return;
  }

  console.error(`FAIL: ${name}`);
  failures++;
}

let failures = 0;

const main = read('src/main.ts');
const appModule = read('src/app.module.ts');
const jwtGuard = read('src/auth/jwt.guard.ts');
const auth = read('src/auth/auth.service.ts');
const permission = read('src/auth/permission.guard.ts');

const customers = read('src/customers/customers.service.ts');
const opportunities = read('src/opportunities/opportunities.service.ts');
const tasks = read('src/tasks/tasks.service.ts');
const users = read('src/users/users.service.ts');
const automation = read('src/automation/automation.service.ts');

const customersController = read('src/customers/customers.controller.ts');
const opportunitiesController = read('src/opportunities/opportunities.controller.ts');
const tasksController = read('src/tasks/tasks.controller.ts');

console.log('========== CRM SECURITY SMOKE TEST ==========');
console.log('Source-level security checks only');
console.log();

/* =========================================================
   GLOBAL SECURITY
   ========================================================= */

check(
  'JWT_SECRET startup protection',
  main.includes('secret.length < 32') &&
  main.includes('JWT_SECRET must be a strong secret'),
);

check(
  'Global ValidationPipe enabled',
  main.includes('new ValidationPipe') &&
  main.includes('whitelist: true') &&
  main.includes('forbidNonWhitelisted: true'),
);

check(
  'Helmet enabled',
  main.includes('app.use(helmet())'),
);

check(
  'CORS configured from environment',
  main.includes('CORS_ORIGINS') &&
  main.includes('app.enableCors'),
);

check(
  'Global rate limiting enabled',
  appModule.includes('ThrottlerModule') &&
  appModule.includes('ThrottlerGuard'),
);

/* =========================================================
   AUTHENTICATION
   ========================================================= */

check(
  'JWT guard verifies token',
  jwtGuard.includes('jwt.verify'),
);

check(
  'JWT guard uses company context',
  jwtGuard.includes('companyId: payload.companyId') &&
  jwtGuard.includes('req.user'),
);

check(
  'JWT guard rejects suspended companies',
  jwtGuard.includes("user.company.status !== 'ACTIVE'"),
);

check(
  'Refresh tokens are hashed',
  auth.includes('createHash') &&
  auth.includes('hashRefresh') &&
  auth.includes('refreshTokenHash'),
);

check(
  'Refresh tokens are rotated',
  auth.includes('session.revokedAt') &&
  auth.includes('update({where:{id:session.id},data:{revokedAt:new Date()}})') &&
  auth.includes('issueSession(session.user)'),
);

/* =========================================================
   PERMISSIONS
   ========================================================= */

check(
  'Permission guard implemented',
  permission.includes('PermissionGuard') &&
  permission.includes('rolePermission'),
);

check(
  'Customers controller protected',
  customersController.includes('@UseGuards(JwtGuard, PermissionGuard)'),
);

check(
  'Opportunities controller protected',
  opportunitiesController.includes('@UseGuards(JwtGuard, PermissionGuard)'),
);

check(
  'Tasks controller protected',
  tasksController.includes('@UseGuards(JwtGuard, PermissionGuard)'),
);

/* =========================================================
   TENANT ISOLATION — CUSTOMERS
   ========================================================= */

check(
  'Customer list is company-scoped',
  customers.includes('customer.findMany') &&
  customers.includes('companyId'),
);

check(
  'Customer get is company-scoped',
  customers.includes('customer.findFirst') &&
  customers.includes('companyId'),
);

check(
  'Customer update is company-scoped',
  customers.includes('customer.updateMany') &&
  customers.includes('companyId'),
);

check(
  'Customer delete is company-scoped',
  customers.includes('customer.deleteMany') &&
  customers.includes('companyId'),
);

/* =========================================================
   TENANT ISOLATION — OPPORTUNITIES
   ========================================================= */

check(
  'Opportunity list/get is company-scoped',
  opportunities.includes('opportunity.findMany') &&
  opportunities.includes('opportunity.findFirst') &&
  opportunities.includes('companyId'),
);

check(
  'Opportunity update is company-scoped',
  opportunities.includes('opportunity.updateMany') &&
  opportunities.includes('companyId'),
);

check(
  'Opportunity delete is company-scoped',
  opportunities.includes('opportunity.deleteMany') &&
  opportunities.includes('companyId'),
);

/* =========================================================
   TENANT ISOLATION — TASKS
   ========================================================= */

check(
  'Task list/get is company-scoped',
  tasks.includes('task.findMany') &&
  tasks.includes('task.findFirst') &&
  tasks.includes('companyId'),
);

check(
  'Task update is company-scoped',
  tasks.includes('task.updateMany') &&
  tasks.includes('companyId'),
);

check(
  'Task delete is company-scoped',
  tasks.includes('task.deleteMany') &&
  tasks.includes('companyId'),
);

/* =========================================================
   USERS
   ========================================================= */

check(
  'User update is company-scoped',
  users.includes('user.updateMany') &&
  users.includes('companyId'),
);

/* =========================================================
   AUTOMATION ISOLATION
   ========================================================= */

check(
  'Automation rules are company-scoped',
  automation.includes('automationRule.findMany') &&
  automation.includes('companyId'),
);

check(
  'Automation rule update is company-scoped',
  automation.includes('automationRule.updateMany') &&
  automation.includes('companyId'),
);

check(
  'Automation rule delete is company-scoped',
  automation.includes('automationRule.deleteMany') &&
  automation.includes('companyId'),
);

check(
  'Automation validates customer references',
  automation.includes('validateAutomationRefs') &&
  automation.includes('customer.findFirst') &&
  automation.includes('customer outside this company'),
);

check(
  'Automation validates opportunity references',
  automation.includes('validateAutomationRefs') &&
  automation.includes('opportunity.findFirst') &&
  automation.includes('opportunity outside this company'),
);

check(
  'Automation validates user references',
  automation.includes('validateAutomationRefs') &&
  automation.includes('user.findFirst') &&
  automation.includes('user outside this company'),
);

check(
  'Automation customer status update is company-scoped',
  automation.includes('customer.updateMany') &&
  automation.includes('companyId: rule.companyId'),
);

/* =========================================================
   DTO VALIDATION
   ========================================================= */

check(
  'Customer assignedTo uses UUID validation',
  read('src/customers/customers.dto.ts').includes('@IsUUID()'),
);

check(
  'Task access is company-scoped',
  /where:\s*\{[\s\S]*?id,[\s\S]*?companyId,[\s\S]*?\}/.test(
    read('src/tasks/tasks.service.ts'),
  ),
);

check(
  'Opportunity probability is constrained 0-100',
  read('src/opportunities/opportunities.dto.ts').includes('@Min(0)') &&
  read('src/opportunities/opportunities.dto.ts').includes('@Max(100)'),
);

/* =========================================================
   RESULT
   ========================================================= */

console.log();
console.log('========== RESULT ==========');

if (failures === 0) {
  console.log('SECURITY SMOKE TEST: PASS');
  console.log('All source-level security checks passed.');
  process.exit(0);
}

console.error(`SECURITY SMOKE TEST: FAIL (${failures} check(s) failed)`);
process.exit(1);
