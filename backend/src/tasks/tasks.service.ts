import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import { PrismaService } from '../prisma/prisma.service';
import { CreateTaskDto, UpdateTaskDto } from './tasks.dto';
import { AutomationService } from '../automation/automation.service';

import {
  AutomationTriggerDto,
} from '../automation/automation.dto';

import {
  TaskPriority,
  TaskStatus,
} from '@prisma/client';

@Injectable()
export class TasksService {
  constructor(
    private prisma: PrismaService,
    private automation: AutomationService,
  ) {}

  async list(
    companyId: string,
    status?: string,
  ) {
    return this.prisma.task.findMany({
      where: {
        companyId,
        ...(status
          ? {
              status:
                status as TaskStatus,
            }
          : {}),
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
      orderBy: [
        { dueDate: 'asc' },
        { createdAt: 'desc' },
      ],
      take: 300,
    });
  }

  async get(
    companyId: string,
    id: string,
  ) {
    const x =
      await this.prisma.task.findFirst({
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
      throw new NotFoundException(
        'Task not found',
      );
    }

    return x;
  }

  private async validateRefs(
    companyId: string,
    d: any,
  ) {
    if (d.customerId) {
      const x =
        await this.prisma.customer.findFirst({
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
      const x =
        await this.prisma.opportunity.findFirst({
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
      const x =
        await this.prisma.user.findFirst({
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
    await this.validateRefs(
      companyId,
      dto,
    );

    const x =
      await this.prisma.task.create({
        data: {
          companyId,
          title: dto.title,
          description: dto.description,
          customerId: dto.customerId,
          opportunityId: dto.opportunityId,
          assignedTo:
            dto.assignedTo ?? userId,
          dueDate: dto.dueDate
            ? new Date(dto.dueDate)
            : undefined,
          priority: dto.priority
            ? (dto.priority as TaskPriority)
            : undefined,
        },
      });

    const created =
      await this.get(
        companyId,
        x.id,
      );

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
      AutomationTriggerDto.TASK_CREATED,
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
    const cur =
      await this.prisma.task.findFirst({
        where: {
          id,
          companyId,
        },
      });

    if (!cur) {
      throw new NotFoundException(
        'Task not found',
      );
    }

    await this.validateRefs(
      companyId,
      dto,
    );

    const result =
      await this.prisma.task.updateMany({
        where: {
          id,
          companyId,
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

    if (result.count !== 1) {
      throw new NotFoundException('Task not found');
    }

    const x = await this.prisma.task.findFirst({
      where: {
        id,
        companyId,
      },
    });

    if (!x) {
      throw new NotFoundException('Task not found');
    }

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

    return this.get(
      companyId,
      id,
    );
  }

  async remove(
    companyId: string,
    id: string,
  ) {
    const x =
      await this.prisma.task.findFirst({
        where: {
          id,
          companyId,
        },
        select: {
          id: true,
        },
      });

    if (!x) {
      throw new NotFoundException(
        'Task not found',
      );
    }

    const deleted = await this.prisma.task.deleteMany({
      where: {
        id,
        companyId,
      },
    });

    if (deleted.count !== 1) {
      throw new NotFoundException('Task not found');
    }

    return {
      success: true,
    };
  }

  // ═══ Task Comments (Chat) ═══

  async listComments(companyId: string, taskId: string) {
    const task = await this.prisma.task.findFirst({
      where: { id: taskId, companyId },
      select: { id: true },
    });
    if (!task) throw new NotFoundException('المهمة غير موجودة');

    return this.prisma.taskComment.findMany({
      where: { taskId },
      include: {
        user: {
          select: {
            id: true,
            employeeId: true,
            name: true,
            role: true,
          },
        },
      },
      orderBy: { createdAt: 'asc' },
    });
  }

  async addComment(
    companyId: string,
    userId: string,
    taskId: string,
    dto: { message: string },
  ) {
    const task = await this.prisma.task.findFirst({
      where: { id: taskId, companyId },
      select: { id: true, title: true, assignedTo: true },
    });
    if (!task) throw new NotFoundException('المهمة غير موجودة');

    const text = (dto.message ?? '').trim();
    if (!text) throw new BadRequestException('الرسالة فارغة');

    const comment = await this.prisma.taskComment.create({
      data: {
        taskId,
        userId,
        message: text,
      },
      include: {
        user: {
          select: {
            id: true,
            employeeId: true,
            name: true,
            role: true,
          },
        },
      },
    });

    // إشعار للمكلَّف بالمهمة (إن لم يكن هو الكاتب)
    if (task.assignedTo && task.assignedTo !== userId) {
      try {
        await this.prisma.notification.create({
          data: {
            companyId,
            userId: task.assignedTo,
            type: 'TASK_COMMENT',
            title: 'تعليق جديد على مهمتك',
            message: text.length > 80 ? text.substring(0, 80) + '...' : text,
            referenceType: 'Task',
            referenceId: taskId,
          },
        });
      } catch (_) {}
    }

    // إشعار للكاتب إن كان المكلَّف مختلفًا
    if (task.assignedTo && task.assignedTo !== userId) {
      // الكاتب قد يكون المدير، والمكلَّف موظف
    }

    await this.prisma.auditLog.create({
      data: {
        companyId,
        userId,
        action: 'COMMENT',
        entity: 'Task',
        entityId: taskId,
        metadata: { commentId: comment.id },
      },
    });

    return comment;
  }

  async deleteComment(
    companyId: string,
    userId: string,
    role: string,
    taskId: string,
    commentId: string,
  ) {
    const comment = await this.prisma.taskComment.findFirst({
      where: { id: commentId, taskId },
      include: { task: { select: { companyId: true } } },
    });
    if (!comment) throw new NotFoundException('التعليق غير موجود');
    if (comment.task.companyId !== companyId) {
      throw new NotFoundException('التعليق غير موجود');
    }

    const isOwner = comment.userId === userId;
    const isManager =
      role === 'GENERAL_MANAGER' ||
      role === 'REGIONAL_MANAGER' ||
      role === 'BRANCH_MANAGER' ||
      role === 'OWNER' ||
      role === 'ADMIN';

    if (!isOwner && !isManager) {
      throw new BadRequestException('لا تملك صلاحية حذف هذا التعليق');
    }

    await this.prisma.taskComment.delete({ where: { id: commentId } });
    return { success: true };
  }
}