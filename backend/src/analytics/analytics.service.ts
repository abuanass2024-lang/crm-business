import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class AnalyticsService {
  constructor(private prisma: PrismaService) {}

  // ═══════════════════════════════════════════════════════
  // Dashboard (الحالي)
  // ═══════════════════════════════════════════════════════
  async dashboard(companyId: string) {
    const [
      customers,
      activeCustomers,
      opportunities,
      won,
      lost,
      tasks,
      overdue,
      activities,
    ] = await Promise.all([
      this.prisma.customer.count({ where: { companyId } }),
      this.prisma.customer.count({ where: { companyId, status: 'ACTIVE' } }),
      this.prisma.opportunity.findMany({
        where: { companyId },
        select: { stage: true, value: true, probability: true },
      }),
      this.prisma.opportunity.findMany({
        where: { companyId, stage: 'WON' },
        select: { value: true },
      }),
      this.prisma.opportunity.count({ where: { companyId, stage: 'LOST' } }),
      this.prisma.task.count({ where: { companyId } }),
      this.prisma.task.count({
        where: {
          companyId,
          status: { in: ['TODO', 'IN_PROGRESS'] },
          dueDate: { lt: new Date() },
        },
      }),
      this.prisma.activity.count({ where: { companyId } }),
    ]);

    const pipeline = opportunities.filter(
      (o) => !['WON', 'LOST'].includes(o.stage),
    );
    const pipelineValue = pipeline.reduce((s, o) => s + Number(o.value), 0);
    const weightedPipeline = pipeline.reduce(
      (s, o) => s + (Number(o.value) * o.probability) / 100,
      0,
    );
    const wonValue = won.reduce((s, o) => s + Number(o.value), 0);
    const totalClosed = won.length + lost;

    return {
      customers,
      activeCustomers,
      opportunities: opportunities.length,
      pipelineValue,
      weightedPipeline,
      wonValue,
      wonCount: won.length,
      lostCount: lost,
      winRate: totalClosed ? won.length / totalClosed : 0,
      tasks,
      overdueTasks: overdue,
      activities,
    };
  }

  // ═══════════════════════════════════════════════════════
  // Pipeline (الحالي)
  // ═══════════════════════════════════════════════════════
  async pipeline(companyId: string) {
    const rows = await this.prisma.opportunity.findMany({
      where: { companyId },
      select: { stage: true, value: true, probability: true },
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
    return stages.map((stage) => {
      const x = rows.filter((r) => r.stage === stage);
      return {
        stage,
        count: x.length,
        value: x.reduce((s, r) => s + Number(r.value), 0),
        weightedValue: x.reduce(
          (s, r) => s + (Number(r.value) * r.probability) / 100,
          0,
        ),
      };
    });
  }

  // ═══════════════════════════════════════════════════════
  // Employees (الحالي)
  // ═══════════════════════════════════════════════════════
  async employees(companyId: string) {
    const users = await this.prisma.user.findMany({
      where: { companyId, active: true },
      select: { id: true, name: true, role: true, employeeId: true, branch: true },
    });
    return Promise.all(
      users.map(async (u) => ({
        ...u,
        customers: await this.prisma.customer.count({
          where: { companyId, assignedTo: u.id },
        }),
        opportunities: await this.prisma.opportunity.count({
          where: { companyId, assignedTo: u.id },
        }),
        tasksCompleted: await this.prisma.task.count({
          where: { companyId, assignedTo: u.id, status: 'COMPLETED' },
        }),
        activities: await this.prisma.activity.count({
          where: { companyId, userId: u.id },
        }),
      })),
    );
  }

  // ═══════════════════════════════════════════════════════
  // Tasks (الحالي)
  // ═══════════════════════════════════════════════════════
  async tasks(companyId: string) {
    const [total, completed, pending, overdue, cancelled] = await Promise.all([
      this.prisma.task.count({ where: { companyId } }),
      this.prisma.task.count({ where: { companyId, status: 'COMPLETED' } }),
      this.prisma.task.count({
        where: { companyId, status: { in: ['TODO', 'IN_PROGRESS'] } },
      }),
      this.prisma.task.count({
        where: {
          companyId,
          status: { in: ['TODO', 'IN_PROGRESS'] },
          dueDate: { lt: new Date() },
        },
      }),
      this.prisma.task.count({ where: { companyId, status: 'CANCELLED' } }),
    ]);
    return {
      total,
      completed,
      pending,
      overdue,
      cancelled,
      completionRate: total ? completed / total : 0,
    };
  }

  // ═══════════════════════════════════════════════════════
  // 🆕 تقرير العملاء التفصيلي
  // ═══════════════════════════════════════════════════════
  async customersReport(companyId: string) {
    const now = new Date();
    const days7 = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const days30 = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
    const days90 = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000);

    const [
      total,
      byStatus,
      byBranch,
      last7,
      last30,
      last90,
      withInteraction,
      allCustomers,
    ] = await Promise.all([
      this.prisma.customer.count({ where: { companyId } }),
      this.prisma.customer.groupBy({
        by: ['status'],
        where: { companyId },
        _count: { _all: true },
      }),
      this.prisma.customer.groupBy({
        by: ['branch'],
        where: { companyId },
        _count: { _all: true },
      }),
      this.prisma.customer.count({
        where: { companyId, createdAt: { gte: days7 } },
      }),
      this.prisma.customer.count({
        where: { companyId, createdAt: { gte: days30 } },
      }),
      this.prisma.customer.count({
        where: { companyId, createdAt: { gte: days90 } },
      }),
      this.prisma.customer.count({
        where: { companyId, firstInteractionAt: { not: null } },
      }),
      this.prisma.customer.findMany({
        where: { companyId },
        select: { assignedTo: true },
      }),
    ]);

    // حسب الموظف
    const byEmployeeMap = new Map<string, number>();
    for (const c of allCustomers) {
      if (c.assignedTo) {
        byEmployeeMap.set(
          c.assignedTo,
          (byEmployeeMap.get(c.assignedTo) ?? 0) + 1,
        );
      }
    }
    const employeeIds = Array.from(byEmployeeMap.keys());
    const employees = employeeIds.length
      ? await this.prisma.user.findMany({
          where: { id: { in: employeeIds } },
          select: { id: true, name: true, employeeId: true },
        })
      : [];
    const byEmployee = employees
      .map((e) => ({
        id: e.id,
        name: e.name,
        employeeId: e.employeeId ?? '',
        count: byEmployeeMap.get(e.id) ?? 0,
      }))
      .sort((a, b) => b.count - a.count);

    return {
      total,
      byStatus: Object.fromEntries(
        byStatus.map((r) => [r.status, r._count._all]),
      ),
      byBranch: Object.fromEntries(
        byBranch.map((r) => [r.branch ?? 'غير محدد', r._count._all]),
      ),
      byEmployee,
      byPeriod: {
        last7: last7,
        last30: last30,
        last90: last90,
      },
      interacted: withInteraction,
      notInteracted: total - withInteraction,
      conversionRate: total ? withInteraction / total : 0,
    };
  }

  // ═══════════════════════════════════════════════════════
  // 🆕 تقرير المهام التفصيلي
  // ═══════════════════════════════════════════════════════
  async tasksReport(companyId: string) {
    const [
      total,
      byStatus,
      byPriority,
      overdue,
      completedThisWeek,
      allTasks,
    ] = await Promise.all([
      this.prisma.task.count({ where: { companyId } }),
      this.prisma.task.groupBy({
        by: ['status'],
        where: { companyId },
        _count: { _all: true },
      }),
      this.prisma.task.groupBy({
        by: ['priority'],
        where: { companyId },
        _count: { _all: true },
      }),
      this.prisma.task.count({
        where: {
          companyId,
          status: { in: ['TODO', 'IN_PROGRESS'] },
          dueDate: { lt: new Date() },
        },
      }),
      this.prisma.task.count({
        where: {
          companyId,
          status: 'COMPLETED',
          updatedAt: {
            gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000),
          },
        },
      }),
      this.prisma.task.findMany({
        where: { companyId },
        select: { assignedTo: true, status: true },
      }),
    ]);

    // حسب الموظف
    const empMap = new Map<string, { total: number; completed: number }>();
    for (const t of allTasks) {
      if (t.assignedTo) {
        const curr = empMap.get(t.assignedTo) ?? { total: 0, completed: 0 };
        curr.total++;
        if (t.status === 'COMPLETED') curr.completed++;
        empMap.set(t.assignedTo, curr);
      }
    }
    const empIds = Array.from(empMap.keys());
    const employees = empIds.length
      ? await this.prisma.user.findMany({
          where: { id: { in: empIds } },
          select: { id: true, name: true, employeeId: true },
        })
      : [];
    const byEmployee = employees
      .map((e) => {
        const s = empMap.get(e.id) ?? { total: 0, completed: 0 };
        return {
          id: e.id,
          name: e.name,
          employeeId: e.employeeId ?? '',
          total: s.total,
          completed: s.completed,
          completionRate: s.total ? s.completed / s.total : 0,
        };
      })
      .sort((a, b) => b.total - a.total);

    const completed = byStatus.find((r) => r.status === 'COMPLETED')?._count._all ?? 0;

    return {
      total,
      completed,
      byStatus: Object.fromEntries(
        byStatus.map((r) => [r.status, r._count._all]),
      ),
      byPriority: Object.fromEntries(
        byPriority.map((r) => [r.priority, r._count._all]),
      ),
      overdue,
      completedThisWeek,
      completionRate: total ? completed / total : 0,
      byEmployee,
    };
  }

  // ═══════════════════════════════════════════════════════
  // 🆕 تقرير الفرص التفصيلي
  // ═══════════════════════════════════════════════════════
  async opportunitiesReport(companyId: string) {
    const [all, allOpps, allCustomers] = await Promise.all([
      this.prisma.opportunity.findMany({
        where: { companyId },
        select: {
          id: true,
          stage: true,
          value: true,
          probability: true,
          assignedTo: true,
          customerId: true,
          currency: true,
        },
      }),
      this.prisma.opportunity.findMany({
        where: { companyId },
        select: { assignedTo: true, stage: true, value: true },
      }),
      this.prisma.customer.findMany({
        where: { companyId },
        select: { id: true, branch: true },
      }),
    ]);

    const total = all.length;
    const totalValue = all.reduce((s, o) => s + Number(o.value), 0);
    const wonOpps = all.filter((o) => o.stage === 'WON');
    const lostOpps = all.filter((o) => o.stage === 'LOST');
    const pipeline = all.filter((o) => !['WON', 'LOST'].includes(o.stage));
    const pipelineValue = pipeline.reduce((s, o) => s + Number(o.value), 0);
    const weightedPipeline = pipeline.reduce(
      (s, o) => s + (Number(o.value) * o.probability) / 100,
      0,
    );
    const wonValue = wonOpps.reduce((s, o) => s + Number(o.value), 0);

    // حسب المرحلة
    const stages = [
      'LEAD',
      'QUALIFIED',
      'MEETING',
      'PROPOSAL',
      'NEGOTIATION',
      'WON',
      'LOST',
    ];
    const byStage = stages.map((stage) => {
      const x = all.filter((o) => o.stage === stage);
      return {
        stage,
        count: x.length,
        value: x.reduce((s, o) => s + Number(o.value), 0),
      };
    });

    // حسب الموظف
    const empMap = new Map<string, { count: number; value: number; won: number }>();
    for (const o of allOpps) {
      if (o.assignedTo) {
        const curr = empMap.get(o.assignedTo) ?? { count: 0, value: 0, won: 0 };
        curr.count++;
        curr.value += Number(o.value);
        if (o.stage === 'WON') curr.won++;
        empMap.set(o.assignedTo, curr);
      }
    }
    const empIds = Array.from(empMap.keys());
    const empUsers = empIds.length
      ? await this.prisma.user.findMany({
          where: { id: { in: empIds } },
          select: { id: true, name: true, employeeId: true },
        })
      : [];
    const byEmployee = empUsers
      .map((e) => {
        const s = empMap.get(e.id) ?? { count: 0, value: 0, won: 0 };
        return {
          id: e.id,
          name: e.name,
          employeeId: e.employeeId ?? '',
          count: s.count,
          value: s.value,
          won: s.won,
        };
      })
      .sort((a, b) => b.value - a.value);

    // حسب الفرع
    const customerBranchMap = new Map(allCustomers.map((c) => [c.id, c.branch ?? 'غير محدد']));
    const branchMap = new Map<string, { count: number; value: number }>();
    for (const o of all) {
      const br = customerBranchMap.get(o.customerId) ?? 'غير محدد';
      const curr = branchMap.get(br) ?? { count: 0, value: 0 };
      curr.count++;
      curr.value += Number(o.value);
      branchMap.set(br, curr);
    }
    const byBranch = Array.from(branchMap.entries())
      .map(([branch, s]) => ({ branch, count: s.count, value: s.value }))
      .sort((a, b) => b.value - a.value);

    const totalClosed = wonOpps.length + lostOpps.length;
    const winRate = totalClosed ? wonOpps.length / totalClosed : 0;
    const avgDealSize = total ? totalValue / total : 0;
    const avgWonSize = wonOpps.length ? wonValue / wonOpps.length : 0;

    return {
      total,
      totalValue,
      pipelineValue,
      weightedPipeline,
      wonValue,
      wonCount: wonOpps.length,
      lostCount: lostOpps.length,
      winRate,
      avgDealSize,
      avgWonSize,
      byStage,
      byEmployee,
      byBranch,
    };
  }
}
