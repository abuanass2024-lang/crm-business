import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import * as bcrypt from 'bcryptjs';
import { CreateUserDto, UpdateUserDto, TransferUserDto } from './users.dto';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  private scopeFilter(me: any) {
    const role = me.role;
    if (role === 'GENERAL_MANAGER' || role === 'OWNER' || role === 'ADMIN') return {};
    if (role === 'REGIONAL_MANAGER') return { branch: me.branch ?? '__none__' };
    if (role === 'BRANCH_MANAGER') return { branch: me.branch ?? '__none__' };
    throw new ForbiddenException('لا تملك صلاحية عرض المستخدمين');
  }

  async list(me: any) {
    const where = { companyId: me.companyId, ...this.scopeFilter(me) };
    return this.prisma.user.findMany({
      where,
      select: {
        id: true, employeeId: true, name: true, email: true,
        role: true, active: true, branch: true, createdAt: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async create(me: any, dto: CreateUserDto) {
    const existing = await this.prisma.user.findFirst({
      where: { email: dto.email },
    });
    if (existing) throw new BadRequestException('البريد الإلكتروني مستخدم مسبقًا');

    if (dto.employeeId) {
      const dup = await this.prisma.user.findFirst({
        where: { companyId: me.companyId, employeeId: dto.employeeId },
      });
      if (dup) throw new BadRequestException('الرقم الوظيفي مستخدم مسبقًا');
    }

    // مدير الفرع: يجبر branch على فرعه
    let branch = dto.branch;
    if (me.role === 'BRANCH_MANAGER') branch = me.branch;
    // مدير الفروع: يجبر branch على فرعه أو يسمح بأي فرع
    if (me.role === 'REGIONAL_MANAGER') branch = dto.branch ?? me.branch;

    const hash = await bcrypt.hash(dto.password, 12);
    const user = await this.prisma.user.create({
      data: {
        companyId: me.companyId,
        name: dto.name,
        email: dto.email,
        employeeId: dto.employeeId,
        branch,
        passwordHash: hash,
        role: dto.role as any,
      },
      select: {
        id: true, employeeId: true, name: true, email: true,
        role: true, active: true, branch: true, createdAt: true,
      },
    });

    await this.prisma.auditLog.create({
      data: {
        companyId: me.companyId, userId: me.id, action: 'CREATE',
        entity: 'User', entityId: user.id,
        metadata: { employeeId: user.employeeId, role: user.role, branch: user.branch },
      },
    });

    return user;
  }

  async update(me: any, id: string, dto: UpdateUserDto) {
    const target = await this.prisma.user.findFirst({
      where: { id, companyId: me.companyId },
    });
    if (!target) throw new NotFoundException('المستخدم غير موجود');

    if (me.role === 'BRANCH_MANAGER' && target.branch !== me.branch) {
      throw new ForbiddenException('لا يمكنك تعديل مستخدم من فرع آخر');
    }

    const data: any = {};
    if (dto.name !== undefined) data.name = dto.name;
    if (dto.employeeId !== undefined) data.employeeId = dto.employeeId;
    if (dto.active !== undefined) data.active = dto.active;
    if (dto.role !== undefined) data.role = dto.role;
    if (dto.branch !== undefined) {
      if (me.role === 'BRANCH_MANAGER') {
        throw new ForbiddenException('لا يمكنك نقل المستخدمين بين الفروع');
      }
      data.branch = dto.branch;
    }

    const updated = await this.prisma.user.update({
      where: { id },
      data,
      select: {
        id: true, employeeId: true, name: true, email: true,
        role: true, active: true, branch: true, createdAt: true,
      },
    });

    await this.prisma.auditLog.create({
      data: {
        companyId: me.companyId, userId: me.id, action: 'UPDATE',
        entity: 'User', entityId: id, metadata: { changes: dto },
      },
    });

    return updated;
  }

  async transfer(me: any, id: string, dto: TransferUserDto) {
    if (me.role === 'BRANCH_MANAGER') {
      throw new ForbiddenException('لا تملك صلاحية نقل المستخدمين');
    }
    const target = await this.prisma.user.findFirst({
      where: { id, companyId: me.companyId },
    });
    if (!target) throw new NotFoundException('المستخدم غير موجود');
    if (!dto.branch || dto.branch.trim() === '') {
      throw new BadRequestException('يجب تحديد الفرع الجديد');
    }

    const updated = await this.prisma.user.update({
      where: { id },
      data: { branch: dto.branch },
      select: {
        id: true, employeeId: true, name: true, email: true,
        role: true, active: true, branch: true,
      },
    });

    await this.prisma.auditLog.create({
      data: {
        companyId: me.companyId, userId: me.id, action: 'TRANSFER',
        entity: 'User', entityId: id,
        metadata: { from: target.branch, to: dto.branch },
      },
    });

    return updated;
  }

  async remove(me: any, id: string) {
    if (id === me.id) throw new BadRequestException('لا يمكنك حذف حسابك');
    const target = await this.prisma.user.findFirst({
      where: { id, companyId: me.companyId },
    });
    if (!target) throw new NotFoundException('المستخدم غير موجود');
    if (me.role === 'BRANCH_MANAGER' && target.branch !== me.branch) {
      throw new ForbiddenException('لا يمكنك حذف مستخدم من فرع آخر');
    }

    await this.prisma.user.update({
      where: { id },
      data: { active: false },
    });

    await this.prisma.auditLog.create({
      data: {
        companyId: me.companyId, userId: me.id, action: 'DELETE',
        entity: 'User', entityId: id,
        metadata: { employeeId: target.employeeId },
      },
    });

    return { success: true };
  }
}
