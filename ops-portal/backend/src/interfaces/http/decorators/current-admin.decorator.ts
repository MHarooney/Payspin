import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import type { Request } from 'express';
import { AuthenticatedAdmin } from '../guards/admin-jwt.strategy';

export interface AdminRequestContext extends AuthenticatedAdmin {
  ip?: string;
  userAgent?: string;
}

/** Pulls the authenticated admin plus request metadata for audit logging. */
export const CurrentAdmin = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): AdminRequestContext => {
    const request = ctx.switchToHttp().getRequest<Request & { user: AuthenticatedAdmin }>();
    const admin = request.user;
    return {
      ...admin,
      ip: request.ip,
      userAgent: request.get('user-agent') ?? undefined,
    };
  },
);
