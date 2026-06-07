import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AdminRole } from '@payspin/shared-types';
import { ROLES_KEY } from './roles.decorator';
import { AuthenticatedAdmin } from './admin-jwt.strategy';

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const required = this.reflector.getAllAndOverride<AdminRole[] | undefined>(ROLES_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (!required || required.length === 0) {
      return true;
    }

    const request = context.switchToHttp().getRequest<{ user?: AuthenticatedAdmin }>();
    const admin = request.user;
    if (!admin || !required.includes(admin.role)) {
      throw new ForbiddenException('Insufficient role for this action');
    }
    return true;
  }
}
