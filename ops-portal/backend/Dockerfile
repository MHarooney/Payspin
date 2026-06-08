# Payspin Ops API — production image (monorepo root context)
FROM node:20-alpine AS base
RUN apk add --no-cache openssl libc6-compat \
  && corepack enable \
  && corepack prepare pnpm@9.15.0 --activate
WORKDIR /app

FROM base AS deps
COPY pnpm-lock.yaml pnpm-workspace.yaml package.json ./
COPY backend/package.json backend/
COPY backend/prisma backend/prisma
COPY ops-portal/backend/package.json ops-portal/backend/
COPY packages/shared-types/package.json packages/shared-types/
COPY packages/validators/package.json packages/validators/
RUN pnpm install --frozen-lockfile

FROM base AS build
COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/backend/node_modules ./backend/node_modules
COPY --from=deps /app/ops-portal/backend/node_modules ./ops-portal/backend/node_modules
COPY --from=deps /app/packages/shared-types/node_modules ./packages/shared-types/node_modules
COPY --from=deps /app/packages/validators/node_modules ./packages/validators/node_modules
COPY pnpm-lock.yaml pnpm-workspace.yaml package.json tsconfig.base.json ./
COPY backend/package.json backend/
COPY backend/prisma backend/prisma
COPY packages packages
COPY ops-portal/backend ops-portal/backend
RUN pnpm --filter @payspin/shared-types build \
  && pnpm --filter @payspin/validators build \
  && cd backend && pnpm exec prisma generate --schema=./prisma/schema.prisma \
  && pnpm --filter @payspin/ops-backend build

FROM node:20-alpine AS runner
RUN apk add --no-cache openssl libc6-compat wget
WORKDIR /app
ENV NODE_ENV=production
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/packages ./packages
COPY --from=build /app/backend/prisma ./backend/prisma
COPY --from=build /app/backend/node_modules ./backend/node_modules
COPY --from=build /app/ops-portal/backend ./ops-portal/backend
WORKDIR /app/ops-portal/backend
USER node
EXPOSE 3002
HEALTHCHECK --interval=15s --timeout=5s --retries=5 --start-period=25s \
  CMD wget -S -qO /dev/null http://127.0.0.1:3002/admin/v1/dashboard/kpis 2>&1 | grep -q '401'
CMD ["node", "dist/main.js"]
