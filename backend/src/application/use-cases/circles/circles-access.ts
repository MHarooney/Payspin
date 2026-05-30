import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';

export async function loadCircleOrThrow(prisma: PrismaService, circleId: string) {
  const circle = await prisma.circle.findUnique({ where: { id: circleId } });
  if (!circle) throw new NotFoundException('Circle not found');
  return circle;
}

export async function assertHost(circle: { hostUserId: string }, userId: string) {
  if (circle.hostUserId !== userId) {
    throw new ForbiddenException('Only the circle host can perform this action');
  }
}

export async function assertParticipant(
  prisma: PrismaService,
  circleId: string,
  userId: string,
  circle: { hostUserId: string },
) {
  if (circle.hostUserId === userId) return;
  const member = await prisma.circleMember.findFirst({
    where: { circleId, userId, status: 'ACTIVE' },
  });
  if (!member) throw new ForbiddenException('You are not a member of this circle');
}

export async function countActiveMembers(prisma: PrismaService, circleId: string) {
  return prisma.circleMember.count({
    where: { circleId, status: 'ACTIVE' },
  });
}

export async function loadDisplayNames(
  prisma: PrismaService,
  userIds: string[],
): Promise<Map<string, string | null>> {
  if (userIds.length === 0) return new Map();
  const users = await prisma.user.findMany({
    where: { id: { in: userIds } },
    select: { id: true, displayName: true },
  });
  return new Map(users.map((u) => [u.id, u.displayName]));
}
