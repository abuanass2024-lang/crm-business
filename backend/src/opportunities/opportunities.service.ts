import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import { PrismaService } from '../prisma/prisma.service';
import { SubscriptionsService } from '../subscriptions/subscriptions.service';
import { AutomationService } from '../automation/automation.service';
import { AutomationTriggerDto } from '../automation/automation.dto';

import {
  CreateOpportunityDto,
  UpdateOpportunityDto,
} from './opportunities.dto';

@Injectable()
export class OpportunitiesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly automation: AutomationService,
    private readonly subscriptions: SubscriptionsService,
  ) {}

  /**
   * يُسجّل تفاعل العميل: يحدّث lastInteractionAt + firstInteractionAt
   * ويحوّل PROSPECT → CUSTOMER عند أول تعامل.
   */
  private async recordCustomerInteraction(
    companyId: string,
    customerId: string,
  ) {
    try {
      const customer = await this.prisma.customer.findFirst({
        where: { id: customerId, companyId },
        select: { id: true, status: true, firstInteractionAt: true },
      });
      if (!customer) return;

      const now = new Date();
      const data: any = { lastInteractionAt: now };

      if (!customer.firstInteractionAt) {
        data.firstInteractionAt = now;
        if (customer.status === 'PROSPECT') {
          data.status = 'CUSTOMER';
        }
      }

      await this.prisma.customer.update({
        where: { id: customerId },
        data,
      });
    } catch (_) {
      // لا نُفشل العملية الأساسية إن فشل تسجيل التفاعل
    }
  }

  list(companyId: string, stage?: any) {
    return this.prisma.opportunity.findMany({
      where: {
        companyId,
        ...(stage ? { stage } : {}),
      },
      include: {
        customer: {
          select: {
            id: true,
            name: true,
            companyName: true,
          },
        },
      },
      orderBy: {
        updatedAt: 'desc',
      },
      take: 200,
    });
  }

  async get(companyId: string, id: string) {
    const item =
      await this.prisma.opportunity.findFirst({
        where: {
          id,
          companyId,
        },
        include: {
          customer: true,
          stageHistory: {
            orderBy: {
              createdAt: 'desc',
            },
            take: 50,
          },
        },
      });

    if (!item) {
      throw new NotFoundException(
        'Opportunity not found',
      );
    }

    return item;
  }

  async create(
    companyId: string,
    userId: string,
    dto: CreateOpportunityDto,
  ) {
    await this.subscriptions.assertWithinQuota(
      companyId,
      'opportunities',
    );

    const customer =
      await this.prisma.customer.findFirst({
        where: {
          id: dto.customerId,
          companyId,
        },
        select: {
          id: true,
        },
      });

    if (!customer) {
      throw new BadRequestException(
        'Customer does not belong to this company',
      );
    }

    if (dto.assignedTo) {
      const u =
        await this.prisma.user.findFirst({
          where: {
            id: dto.assignedTo,
            companyId,
            active: true,
          },
          select: {
            id: true,
          },
        });

      if (!u) {
        throw new BadRequestException(
          'Assigned user does not belong to this company',
        );
      }
    }

    const stage = dto.stage ?? 'LEAD';

    const item =
      await this.prisma.opportunity.create({
        data: {
          companyId,
          customerId: dto.customerId,
          title: dto.title,
          value: dto.value,
          currency: dto.currency ?? 'YER',
          stage,
          probability:
            dto.probability ?? 10,
          expectedCloseDate:
            dto.expectedCloseDate
              ? new Date(dto.expectedCloseDate)
              : undefined,
          assignedTo: dto.assignedTo,
          stageHistory: {
            create: {
              companyId,
              toStage: stage,
              changedBy: userId,
            },
          },
        },
      });

    await this.prisma.auditLog.create({
      data: {
        companyId,
        userId,
        action: 'CREATE',
        entity: 'Opportunity',
        entityId: item.id,
        metadata: {
          newValue: item,
        },
      },
    });

    // ربط العميل: تسجيل أول تعامل
    await this.recordCustomerInteraction(
      companyId,
      item.customerId,
    );

    await this.automation.onEvent(
      companyId,
      AutomationTriggerDto.OPPORTUNITY_CREATED,
      {
        opportunity: item,
        opportunityId: item.id,
        entityId: item.id,
        userId,
      },
    );

    return item;
  }

  async update(
    companyId: string,
    userId: string,
    id: string,
    dto: UpdateOpportunityDto,
  ) {
    const current =
      await this.prisma.opportunity.findFirst({
        where: {
          id,
          companyId,
        },
      });

    if (!current) {
      throw new NotFoundException(
        'Opportunity not found',
      );
    }

    if (dto.customerId) {
      const customer = await this.prisma.customer.findFirst({
        where: {
          id: dto.customerId,
          companyId,
        },
        select: {
          id: true,
        },
      });

      if (!customer) {
        throw new BadRequestException(
          'Customer does not belong to this company',
        );
      }
    }

    if (dto.assignedTo) {
      const assignee = await this.prisma.user.findFirst({
        where: {
          id: dto.assignedTo,
          companyId,
          active: true,
        },
        select: {
          id: true,
        },
      });

      if (!assignee) {
        throw new BadRequestException(
          'Assigned user does not belong to this company or is inactive',
        );
      }
    }

    if (
      dto.stage &&
      dto.stage !== current.stage
    ) {
      const updated =
        await this.prisma.$transaction(
          async (tx) => {
            const u =
              await tx.opportunity.updateMany({
                where: {
                  id,
                  companyId,
                },
                data: {
                  ...dto,
                  expectedCloseDate:
                    dto.expectedCloseDate
                      ? new Date(
                          dto.expectedCloseDate,
                        )
                      : undefined,
                },
              });

            if (u.count !== 1) {
              throw new NotFoundException(
                'Opportunity not found',
              );
            }

            const result =
              await tx.opportunity.findFirst({
                where: {
                  id,
                  companyId,
                },
              });

            if (!result) {
              throw new NotFoundException(
                'Opportunity not found',
              );
            }

            await tx.opportunityStageHistory.create(
              {
                data: {
                  companyId,
                  opportunityId: id,
                  fromStage:
                    current.stage,
                  toStage:
                    dto.stage!,
                  changedBy: userId,
                },
              },
            );

            return result;
          },
        );

      await this.prisma.auditLog.create({
        data: {
          companyId,
          userId,
          action: 'STAGE_CHANGED',
          entity: 'Opportunity',
          entityId: id,
          metadata: {
            oldValue: {
              stage: current.stage,
            },
            newValue: {
              stage: dto.stage,
            },
          },
        },
      });

      const ctx = {
        opportunity: updated,
        opportunityId: id,
        entityId: id,
        userId,
        fromStage: current.stage,
        toStage: dto.stage,
        customerId:
          updated.customerId,
      };

      await this.automation.onEvent(
        companyId,
        AutomationTriggerDto.OPPORTUNITY_STAGE_CHANGED,
        ctx,
      );

      if (dto.stage === 'WON') {
        // تحويل العميل تلقائيًا عند الفوز
        await this.recordCustomerInteraction(
          companyId,
          updated.customerId,
        );

        await this.automation.onEvent(
          companyId,
          AutomationTriggerDto.OPPORTUNITY_WON,
          ctx,
        );
      }

      if (dto.stage === 'LOST') {
        await this.automation.onEvent(
          companyId,
          AutomationTriggerDto.OPPORTUNITY_LOST,
          ctx,
        );
      }

      return this.get(
        companyId,
        id,
      );
    }

    const result =
      await this.prisma.opportunity.updateMany({
        where: {
          id,
          companyId,
        },
        data: {
          ...dto,
          expectedCloseDate:
            dto.expectedCloseDate
              ? new Date(
                  dto.expectedCloseDate,
                )
              : undefined,
        },
      });

    if (result.count !== 1) {
      throw new NotFoundException(
        'Opportunity not found',
      );
    }

    const x =
      await this.prisma.opportunity.findFirst({
        where: {
          id,
          companyId,
        },
      });

    if (!x) {
      throw new NotFoundException(
        'Opportunity not found',
      );
    }

    await this.prisma.auditLog.create({
      data: {
        companyId,
        userId,
        action: 'UPDATE',
        entity: 'Opportunity',
        entityId: id,
        metadata: {
          oldValue: current,
          newValue: x,
        },
      },
    });

    return x;
  }

  async remove(
    companyId: string,
    id: string,
  ) {
    const exists =
      await this.prisma.opportunity.findFirst({
        where: {
          id,
          companyId,
        },
        select: {
          id: true,
        },
      });

    if (!exists) {
      throw new NotFoundException(
        'Opportunity not found',
      );
    }

    const deleted =
      await this.prisma.opportunity.deleteMany({
        where: {
          id,
          companyId,
        },
      });

    if (deleted.count !== 1) {
      throw new NotFoundException(
        'Opportunity not found',
      );
    }

    return {
      success: true,
    };
  }

  async pipeline(companyId: string) {
    const rows =
      await this.prisma.opportunity.groupBy({
        by: ['stage'],
        where: {
          companyId,
        },
        _count: {
          _all: true,
        },
        _sum: {
          value: true,
        },
      });

    const stages = [
      'LEAD',
      'QUALIFIED',
      'MEETING',
      'PROPOSAL',
      'NEGOTIATION',
      'WON',
      'LOST',
    ];

    const byStage =
      Object.fromEntries(
        stages.map((s) => [
          s,
          {
            count: 0,
            value: 0,
          },
        ]),
      );

    for (const r of rows) {
      byStage[r.stage] = {
        count: r._count._all,
        value: Number(
          r._sum.value ?? 0,
        ),
      };
    }

    const active = stages.filter(
      (s) =>
        !['WON', 'LOST'].includes(s),
    );

    const pipelineValue =
      active.reduce(
        (a, s) =>
          a + byStage[s].value,
        0,
      );

    const weightedPipeline =
      active.reduce(
        (a, s) =>
          a +
          byStage[s].value *
            this.probabilityForStage(s),
        0,
      );

    return {
      stages: byStage,
      pipelineValue,
      weightedPipeline,
    };
  }

  private probabilityForStage(
    stage: string,
  ) {
    return (
      {
        LEAD: 0.1,
        QUALIFIED: 0.25,
        MEETING: 0.4,
        PROPOSAL: 0.6,
        NEGOTIATION: 0.8,
      } as Record<string, number>
    )[stage] ?? 0;
  }
}