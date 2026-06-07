import { SetMetadata } from '@nestjs/common';
import { AdminRole } from '@payspin/shared-types';

export const ROLES_KEY = 'requiredRoles';

/** Restrict a route to admins whose role is one of the listed roles. */
export const Roles = (...roles: AdminRole[]) => SetMetadata(ROLES_KEY, roles);
