import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import {
  AutomationAction,
  AutomationTrigger,
  TaskPriority,
  TaskStatus,
} from '@prisma/client';

import { PrismaService } from '../prisma/prisma.service';

import {
  AutomationActionDto,
  AutomationTriggerDto,
  CreateAutomationRuleDto,
  UpdateAutomationRuleDto,
} from './automation.dto';

@Injectable()
export class AutomationService {
  constructor(private prisma: PrismaService) {}

  listRules(companyId: string) {
    return this.prisma.automationRule.findMany({
      where: { companyId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async createRule(
    companyId: string,
    userId: string,
    d: CreateAutomationRuleDto,
  ) {
    if (!d.name?.trim()) {
      throw new BadRequestException('Rule name is required');
    }

    const x = await this.prisma.automationRule.create({
      data: {
        companyId,
        name: d.name.trim(),
        description: d.description,
        trigger: d.trigger as AutomationTrigger,
        condition: d.condition,
        action: d.action as AutomationAction,
        actionData: d.actionData,
        enabled: d.enabled ?? true,
        createdBy: userId,
      },
    });

    await this.audit(
      companyId,
      userId,
      'CREATE',
      'AutomationRule',
      x.id,
      null,
      x,
    );

    return x;
  }

  async updateRule(
    companyId: string,
    userId: string,
    id: string,
    d: UpdateAutomationRuleDto,
  ) {
    const old = await this.prisma.automationRule.findFirst({
      where: {
        id,
        companyId,
      },
    });

    if (!old) {
      throw new NotFoundException('Automation rule not found');
    }

    const x = await this.prisma.automationRule.update({
      where: { id },
      data: {
        name: d.name,
        description: d.description,
        trigger: d.trigger as AutomationTrigger,
        condition: d.condition,
        action: d.action as AutomationAction,
        actionData: d.actionData,
        enabled: d.enabled,
      },
    });

    await this.audit(
      companyId,
      userId,
      'UPDATE',
      'AutomationRule',
      id,
      old,
      x,
    );

    return x;
  }

  async removeRule(
    companyId: string,
    userId: string,
    id: string,
  ) {
    const old = await this.prisma.automationRule.findFirst({
      where: {
        id,
        companyId,
      },
    });

    if (!old) {
      throw new NotFoundException('Automation rule not found');
    }

    await this.prisma.automationRule.delete({
      where: { id },
    });

    await this.audit(
      companyId,
      userId,
      'DELETE',
      'AutomationRule',
      id,
      old,
      null,
    );

    return { success: true };
  }

  listExecutions(companyId: string, limit = 100) {
    return this.prisma.automationExecution.findMany({
      where: { companyId },
      include: {
        rule: {
          select: {
            id: true,
            name: true,
            trigger: true,
            action: true,
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
      take: Math.min(limit, 500),
    });
  }

  async onEvent(
    companyId: string,
    trigger: AutomationTriggerDto,
    context: any,
  ) {
    const rules = await this.prisma.automationRule.findMany({
      where: {
        companyId,
        enabled: true,
        trigger: trigger as AutomationTrigger,
      },
    });

    const out: any[] = [];

    for (const rule of rules) {
      if (!this.matches(rule.condition, context)) {
        continue;
      }

      out.push(await this.executeRule(rule, context));
    }

    return out;
  }

  async runDue(companyId: string) {
    const now = new Date();

    const dueSoon = new Date(
      now.getTime() + 24 * 60 * 60 * 1000,
    );

    const tasks = await this.prisma.task.findMany({
      where: {
        companyId,
        status: {
          in: [
            TaskStatus.TODO,
            TaskStatus.IN_PROGRESS,
          ],
        },
        dueDate: {
          not: null,
          lte: dueSoon,
        },
      },
      select: {
        id: true,
        companyId: true,
        title: true,
        dueDate: true,
        assignedTo: true,
        customerId: true,
        opportunityId: true,
        status: true,
      },
    });

    let executed = 0;

    for (const t of tasks) {
      const trigger =
        t.dueDate && t.dueDate < now
          ? AutomationTriggerDto.TASK_OVERDUE
          : AutomationTriggerDto.TASK_DUE_SOON;

      const results = await this.onEvent(
        companyId,
        trigger,
        {
          task: t,
          taskId: t.id,
          entityId: t.id,
        },
      );

      executed += results.length;
    }

    return {
      checked: tasks.length,
      executed,
    };
  }

  private matches(condition: any, ctx: any) {
    if (!condition) {
      return true;
    }

    return Object.entries(condition).every(
      ([key, val]) => {
        const actual = this.resolve(key, ctx);

        if (Array.isArray(val)) {
          return val
            .map(String)
            .includes(String(actual));
        }

        return (
          String(actual ?? '') ===
          String(val)
        );
      },
    );
  }

  private resolve(path: string, ctx: any) {
    return path
      .split('.')
      .reduce(
        (o, k) => o?.[k],
        ctx,
      );
  }

  private async executeRule(
    rule: any,
    ctx: any,
  ) {
    const executionKey = this.key(
      rule.trigger,
      ctx,
    );

    try {
      const existing =
        await this.prisma.automationExecution.findUnique({
          where: {
            ruleId_executionKey: {
              ruleId: rule.id,
              executionKey,
            },
          },
        });

      if (existing) {
        return existing;
      }

      let result: any;

      const d = rule.actionData || {};

      switch (rule.action as AutomationActionDto) {
        case AutomationActionDto.CREATE_TASK: {
          const source =
            ctx.task ||
            ctx.opportunity ||
            {};

          const due = new Date(
            Date.now() +
              Number(d.dueInDays ?? 1) *
                86400000,
          );

          const assignee =
            d.assignedTo ||
            source.assignedTo ||
            ctx.userId;

          result =
            await this.prisma.task.create({
              data: {
                companyId: rule.companyId,
                title:
                  d.title ||
                  `متابعة آلية: ${
                    source.title ||
                    'سجل CRM'
                  }`,
                description:
                  d.description ||
                  'تم إنشاؤها بواسطة قاعدة أتمتة',
                customerId:
                  d.customerId ||
                  source.customerId,
                opportunityId:
                  d.opportunityId ||
                  source.id,
                assignedTo: assignee,
                dueDate: due,
                priority:
                  (d.priority as TaskPriority) ||
                  TaskPriority.MEDIUM,
              },
            });

          break;
        }

        case AutomationActionDto.CREATE_NOTIFICATION: {
          const userId =
            d.userId ||
            ctx.userId ||
            ctx.assignedTo;

          if (!userId) {
            throw new BadRequestException(
              'CREATE_NOTIFICATION requires userId or context user',
            );
          }

          result =
            await this.prisma.notification.create({
              data: {
                companyId: rule.companyId,
                userId,
                type: 'AUTOMATION',
                title:
                  d.title ||
                  rule.name,
                message:
                  d.message ||
                  'إشعار من قاعدة أتمتة',
                referenceType:
                  d.referenceType,
                referenceId:
                  d.referenceId ||
                  ctx.entityId,
              },
            });

          break;
        }

        case AutomationActionDto.CHANGE_CUSTOMER_STATUS: {
          const customerId =
            d.customerId ||
            ctx.customerId ||
            ctx.opportunity?.customerId;

          if (!customerId) {
            throw new BadRequestException(
              'Customer is required',
            );
          }

          result =
            await this.prisma.customer.update({
              where: {
                id: customerId,
              },
              data: {
                status: String(
                  d.status || 'ACTIVE',
                ),
              },
            });

          break;
        }

        case AutomationActionDto.LOG_ACTIVITY: {
          const userId =
            ctx.userId ||
            d.userId;

          if (!userId) {
            throw new BadRequestException(
              'LOG_ACTIVITY requires userId in context or actionData',
            );
          }

          result =
            await this.prisma.activity.create({
              data: {
                companyId: rule.companyId,
                userId,
                customerId:
                  d.customerId ||
                  ctx.customerId ||
                  ctx.opportunity?.customerId,
                opportunityId:
                  d.opportunityId ||
                  ctx.opportunityId ||
                  ctx.opportunity?.id,
                type: 'AUTOMATION',
                description:
                  d.description ||
                  rule.name,
              },
            });

          break;
        }

        default:
          throw new BadRequestException(
            `Unsupported automation action: ${rule.action}`,
          );
      }

      return await this.prisma.automationExecution.create({
        data: {
          companyId: rule.companyId,
          ruleId: rule.id,
          executionKey,
          trigger:
            rule.trigger as AutomationTrigger,
          status: 'SUCCESS',
          context: this.clean(ctx),
          result: this.clean(result),
        },
      });
    } catch (e: any) {
      try {
        return await this.prisma.automationExecution.create({
          data: {
            companyId: rule.companyId,
            ruleId: rule.id,
            executionKey,
            trigger:
              rule.trigger as AutomationTrigger,
            status: 'FAILED',
            context: this.clean(ctx),
            error:
              e?.message ||
              String(e),
          },
        });
      } catch {
        return {
          status: 'FAILED',
          error:
            e?.message ||
            String(e),
        };
      }
    }
  }

  private key(
    trigger: string,
    ctx: any,
  ) {
    return `${trigger}:${
      ctx.entityId ||
      ctx.taskId ||
      ctx.opportunityId ||
      ctx.customerId ||
      JSON.stringify(ctx).slice(0, 180)
    }`;
  }

  private audit(
    companyId: string,
    userId: string | undefined,
    action: string,
    entity: string,
    entityId: string,
    oldValue: any,
    newValue: any,
  ) {
    return this.prisma.auditLog.create({
      data: {
        companyId,
        userId,
        action,
        entity,
        entityId,
        metadata: {
          oldValue: this.clean(oldValue),
          newValue: this.clean(newValue),
        },
      },
    });
  }

  private clean(x: any) {
    if (x === undefined) {
      return null;
    }

    try {
      return JSON.parse(
        JSON.stringify(x),
      );
    } catch {
      return String(x);
    }
  }
}