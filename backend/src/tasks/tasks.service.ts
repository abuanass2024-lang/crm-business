import {
BadRequestException,
Injectable,
NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateTaskDto, UpdateTaskDto } from './tasks.dto';
import { AutomationService } from '../automation/automation.service';
import { TaskPriority, TaskStatus } from '@prisma/client';

@Injectable()
export class TasksService {
constructor(
private prisma: PrismaService,
private automation: AutomationService,
) {}

async list(companyId: string, status?: string) {
return this.prisma.task.findMany({
where: {
companyId,
...(status ? { status: status as TaskStatus } : {}),
},
include: {
customer: {
select: {
id: true,
name: true,
},
},
opportunity: {
select: {
id: true,
title: true,
},
},
assignee: {
select: {
id: true,
name: true,
},
},
},
orderBy: [{ dueDate: 'asc' }, { createdAt: 'desc' }],
take: 300,
});
}

async get(companyId: string, id: string) {
const x = await this.prisma.task.findFirst({
where: {
id,
companyId,
},
include: {
customer: true,
opportunity: true,
assignee: {
select: {
id: true,
name: true,
email: true,
},
},
},
});

if (!x) {
  throw new NotFoundException('Task not found');
}

return x;

}

private async validateRefs(companyId: string, d: any) {
if (d.customerId) {
const x = await this.prisma.customer.findFirst({
where: {
id: d.customerId,
companyId,
},
select: {
id: true,
},
});

  if (!x) {
    throw new BadRequestException(
      'Customer does not belong to this company',
    );
  }
}

if (d.opportunityId) {
  const x = await this.prisma.opportunity.findFirst({
    where: {
      id: d.opportunityId,
      companyId,
    },
    select: {
      id: true,
    },
  });

  if (!x) {
    throw new BadRequestException(
      'Opportunity does not belong to this company',
    );
  }
}

if (d.assignedTo) {
  const x = await this.prisma.user.findFirst({
    where: {
      id: d.assignedTo,
      companyId,
      active: true,
    },
    select: {
      id: true,
    },
  });

  if (!x) {
    throw new BadRequestException(
      'Assignee does not belong to this company',
    );
  }
}

}

async create(
companyId: string,
userId: string,
dto: CreateTaskDto,
) {
await this.validateRefs(companyId, dto);

const x = await this.prisma.task.create({
  data: {
    companyId,
    title: dto.title,
    description: dto.description,
    customerId: dto.customerId,
    opportunityId: dto.opportunityId,
    assignedTo: dto.assignedTo ?? userId,
    dueDate: dto.dueDate
      ? new Date(dto.dueDate)
      : undefined,
    priority: dto.priority
      ? (dto.priority as TaskPriority)
      : undefined,
  },
});

const created = await this.get(companyId, x.id);

await this.prisma.auditLog.create({
  data: {
    companyId,
    userId,
    action: 'CREATE',
    entity: 'Task',
    entityId: x.id,
    metadata: {
      newValue: created,
    },
  },
});

await this.automation.onEvent(
  companyId,
  'TASK_CREATED',
  {
    task: created,
    taskId: created.id,
    entityId: created.id,
    userId,
  },
);

return created;

}

async update(
companyId: string,
id: string,
dto: UpdateTaskDto,
) {
const cur = await this.prisma.task.findFirst({
where: {
id,
companyId,
},
});

if (!cur) {
  throw new NotFoundException('Task not found');
}

await this.validateRefs(companyId, dto);

const x = await this.prisma.task.update({
  where: {
    id,
  },
  data: {
    title: dto.title,
    description: dto.description,
    customerId: dto.customerId,
    opportunityId: dto.opportunityId,
    assignedTo: dto.assignedTo,
    dueDate: dto.dueDate
      ? new Date(dto.dueDate)
      : undefined,
    priority: dto.priority
      ? (dto.priority as TaskPriority)
      : undefined,
    status: dto.status
      ? (dto.status as TaskStatus)
      : undefined,
  },
});

await this.prisma.auditLog.create({
  data: {
    companyId,
    action: 'UPDATE',
    entity: 'Task',
    entityId: id,
    metadata: {
      oldValue: cur,
      newValue: x,
    },
  },
});

return this.get(companyId, id);

}

async remove(companyId: string, id: string) {
const x = await this.prisma.task.findFirst({
where: {
id,
companyId,
},
select: {
id: true,
},
});

if (!x) {
  throw new NotFoundException('Task not found');
}

await this.prisma.task.delete({
  where: {
    id,
  },
});

return {
  success: true,
};

}
}