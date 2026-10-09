import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { SubscriptionsService } from '../subscriptions/subscriptions.service';
import { CreateCustomerDto, UpdateCustomerDto } from './customers.dto';
import { AutomationService } from '../automation/automation.service';
import { AutomationTriggerDto } from '../automation/automation.dto';

@Injectable()
export class CustomersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly automation: AutomationService,
    private readonly subscriptions: SubscriptionsService,
  ) {}

  list(companyId: string, q?: string) {
    return this.prisma.customer.findMany({
      where: {
        companyId,
        ...(q
          ? {
              OR: [
                {
                  name: {
                    contains: q,
                    mode: 'insensitive',
                  },
                },
                {
                  companyName: {
                    contains: q,
                    mode: 'insensitive',
                  },
                },
                {
                  phone: {
                    contains: q,
                    mode: 'insensitive',
                  },
                },
                {
                  email: {
                    contains: q,
                    mode: 'insensitive',
                  },
                },
              ],
            }
          : {}),
      },
      orderBy: {
        createdAt: 'desc',
      },
      take: 100,
    });
  }

  async get(companyId: string, id: string) {
    const customer = await this.prisma.customer.findFirst({
      where: {
        id,
        companyId,
      },
      include: {
        opportunities: {
          orderBy: {
            createdAt: 'desc',
          },
          take: 20,
        },
        tasks: {
          orderBy: {
            dueDate: 'asc',
          },
          take: 20,
        },
        activities: {
          orderBy: {
            createdAt: 'desc',
          },
          take: 30,
        },
      },
    });

    if (!customer) {
      throw new NotFoundException('Customer not found');
    }

    return customer;
  }

  /**
   * تسجيل تعامل: يُحدّث lastInteractionAt
   * ويحوّل PROSPECT → CUSTOMER عند أول تعامل.
   */
  async recordInteraction(companyId: string, customerId: string) {
    const customer = await this.prisma.customer.findFirst({
      where: { id: customerId, companyId },
    });
    if (!customer) return null;

    const now = new Date();
    const data: any = { lastInteractionAt: now };

    // أول تعامل: كان PROSPECT → يصبح CUSTOMER
    if (!customer.firstInteractionAt) {
      data.firstInteractionAt = now;
      if (customer.status === 'PROSPECT') {
        data.status = 'CUSTOMER';
      }
    }

    return this.prisma.customer.update({
      where: { id: customerId },
      data,
    });
  }

  async create(companyId: string, dto: CreateCustomerDto) {
    await this.subscriptions.assertWithinQuota(companyId, 'customers');

    if (dto.assignedTo) {
      const u = await this.prisma.user.findFirst({
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
        throw new NotFoundException(
          'Assigned user not found in this company',
        );
      }
    }

    const x = await this.prisma.customer.create({
      data: {
        companyId,
        ...dto,
      },
    });

    await this.prisma.auditLog.create({
      data: {
        companyId,
        action: 'CREATE',
        entity: 'Customer',
        entityId: x.id,
        metadata: {
          newValue: x,
        },
      },
    });

    await this.automation.onEvent(
      companyId,
      AutomationTriggerDto.CUSTOMER_CREATED,
      {
        customer: x,
        customerId: x.id,
        entityId: x.id,
      },
    );

    return x;
  }

  async update(
    companyId: string,
    id: string,
    dto: UpdateCustomerDto,
  ) {
    const exists = await this.prisma.customer.findFirst({
      where: {
        id,
        companyId,
      },
      select: {
        id: true,
      },
    });

    if (!exists) {
      throw new NotFoundException('Customer not found');
    }

    const old = await this.prisma.customer.findFirst({
      where: {
        id,
        companyId,
      },
    });

    if (dto.assignedTo) {
      const u = await this.prisma.user.findFirst({
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
        throw new NotFoundException(
          'Assigned user not found in this company',
        );
      }
    }

    const result = await this.prisma.customer.updateMany({
      where: {
        id,
        companyId,
      },
      data: dto,
    });

    if (result.count !== 1) {
      throw new NotFoundException('Customer not found');
    }

    const x = await this.prisma.customer.findFirst({
      where: {
        id,
        companyId,
      },
    });

    if (!x) {
      throw new NotFoundException('Customer not found');
    }

    await this.prisma.auditLog.create({
      data: {
        companyId,
        action: 'UPDATE',
        entity: 'Customer',
        entityId: id,
        metadata: {
          oldValue: old,
          newValue: x,
        },
      },
    });

    return x;
  }

  async remove(companyId: string, id: string) {
    const exists = await this.prisma.customer.findFirst({
      where: {
        id,
        companyId,
      },
      select: {
        id: true,
      },
    });

    if (!exists) {
      throw new NotFoundException('Customer not found');
    }

    const old = await this.prisma.customer.findFirst({
      where: {
        id,
        companyId,
      },
    });

    const deleted = await this.prisma.customer.deleteMany({
      where: {
        id,
        companyId,
      },
    });

    if (deleted.count !== 1) {
      throw new NotFoundException('Customer not found');
    }

    await this.prisma.auditLog.create({
      data: {
        companyId,
        action: 'DELETE',
        entity: 'Customer',
        entityId: id,
        metadata: {
          oldValue: old,
        },
      },
    });

    return {
      success: true,
    };
  }
}
