import { Body, Controller, Delete, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { AdminRole, AdminStaffListItem } from '@payspin/shared-types';
import { createAdminStaffSchema, patchAdminStaffSchema } from '@payspin/validators';
import * as bcrypt from 'bcrypt';
import { BadRequestException, ConflictException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { AuditService } from '../../../infrastructure/audit/audit.service';
import { AuditAction } from '../../../domain/constants';
import { CurrentAdmin, AdminRequestContext } from '../decorators/current-admin.decorator';
import { AdminJwtAuthGuard } from '../guards/admin-jwt-auth.guard';
import { RolesGuard } from '../guards/roles.guard';
import { Roles } from '../guards/roles.decorator';

@Controller('admin-users')
@UseGuards(AdminJwtAuthGuard, RolesGuard)
@Roles(AdminRole.SUPER_ADMIN)
export class AdminUsersController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
  ) {}

  @Get()
  async list(): Promise<AdminStaffListItem[]> {
    const admins = await this.prisma.adminUser.findMany({ orderBy: { createdAt: 'desc' } });
    return admins.map((a) => ({
      id: a.id,
      email: a.email,
      displayName: a.displayName,
      role: a.role as AdminRole,
      isActive: a.isActive,
      lastLoginAt: a.lastLoginAt?.toISOString() ?? null,
      createdAt: a.createdAt.toISOString(),
    }));
  }

  @Get(':id')
  async detail(@Param('id') id: string): Promise<AdminStaffListItem> {
    const a = await this.prisma.adminUser.findUnique({ where: { id } });
    if (!a) throw new NotFoundException('Admin user not found');
    return {
      id: a.id,
      email: a.email,
      displayName: a.displayName,
      role: a.role as AdminRole,
      isActive: a.isActive,
      lastLoginAt: a.lastLoginAt?.toISOString() ?? null,
      createdAt: a.createdAt.toISOString(),
    };
  }

  @Post()
  async create(@Body() body: unknown, @CurrentAdmin() admin: AdminRequestContext) {
    const input = createAdminStaffSchema.parse(body);
    const email = input.email.toLowerCase();
    const exists = await this.prisma.adminUser.findUnique({ where: { email } });
    if (exists) throw new ConflictException('Admin user with that email already exists');

    const passwordHash = await bcrypt.hash(input.tempPassword, 10);
    const created = await this.prisma.adminUser.create({
      data: { email, displayName: input.displayName ?? null, role: input.role, passwordHash },
    });

    await this.audit.record(
      { adminUserId: admin.adminUserId, adminEmail: admin.email, ip: admin.ip, userAgent: admin.userAgent },
      { action: AuditAction.ADMIN_USER_CREATE, targetType: 'admin_user', targetId: created.id, after: { email, role: input.role } },
    );

    return { id: created.id, email: created.email, role: created.role };
  }

  @Patch(':id')
  async update(@Param('id') id: string, @Body() body: unknown, @CurrentAdmin() admin: AdminRequestContext) {
    const input = patchAdminStaffSchema.parse(body);
    const target = await this.prisma.adminUser.findUnique({ where: { id } });
    if (!target) throw new NotFoundException('Admin user not found');

    // Cannot deactivate self
    if (input.isActive === false && id === admin.adminUserId) {
      throw new BadRequestException('Cannot deactivate your own account');
    }

    // Cannot remove last SUPER_ADMIN
    if (input.role && input.role !== 'SUPER_ADMIN' && target.role === 'SUPER_ADMIN') {
      const superCount = await this.prisma.adminUser.count({ where: { role: 'SUPER_ADMIN', isActive: true } });
      if (superCount <= 1) throw new BadRequestException('Cannot downgrade the last active SUPER_ADMIN');
    }

    const updated = await this.prisma.adminUser.update({
      where: { id },
      data: {
        ...(input.displayName !== undefined ? { displayName: input.displayName } : {}),
        ...(input.role ? { role: input.role } : {}),
        ...(input.isActive !== undefined ? { isActive: input.isActive } : {}),
      },
    });

    await this.audit.record(
      { adminUserId: admin.adminUserId, adminEmail: admin.email, ip: admin.ip, userAgent: admin.userAgent },
      { action: AuditAction.ADMIN_USER_UPDATE, targetType: 'admin_user', targetId: id, after: input },
    );

    return { id: updated.id, role: updated.role, isActive: updated.isActive };
  }

  @Delete(':id')
  async deactivate(@Param('id') id: string, @CurrentAdmin() admin: AdminRequestContext) {
    const target = await this.prisma.adminUser.findUnique({ where: { id } });
    if (!target) throw new NotFoundException('Admin user not found');

    if (id === admin.adminUserId) throw new BadRequestException('Cannot deactivate your own account');

    if (target.role === 'SUPER_ADMIN') {
      const superCount = await this.prisma.adminUser.count({ where: { role: 'SUPER_ADMIN', isActive: true } });
      if (superCount <= 1) throw new BadRequestException('Cannot deactivate the last active SUPER_ADMIN');
    }

    await this.prisma.adminUser.update({ where: { id }, data: { isActive: false } });

    await this.audit.record(
      { adminUserId: admin.adminUserId, adminEmail: admin.email, ip: admin.ip, userAgent: admin.userAgent },
      { action: AuditAction.ADMIN_USER_DEACTIVATE, targetType: 'admin_user', targetId: id },
    );

    return { id, isActive: false };
  }
}
