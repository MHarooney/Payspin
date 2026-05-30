# Payspin API — production image (monorepo root context)
FROM node:20-alpine AS base
RUN apk add --no-cache openssl libc6-compat \
  && corepack enable \
  && corepack prepare pnpm@9.15.0 --activate
WORKDIR /app

FROM base AS deps
COPY pnpm-lock.yaml pnpm-workspace.yaml package.json ./
COPY backend/package.json backend/
COPY packages/pisp-provider/package.json packages/pisp-provider/
COPY packages/shared-types/package.json packages/shared-types/
COPY packages/validators/package.json packages/validators/
RUN pnpm install --frozen-lockfile

FROM base AS build
COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/backend/node_modules ./backend/node_modules
COPY --from=deps /app/packages/pisp-provider/node_modules ./packages/pisp-provider/node_modules
COPY --from=deps /app/packages/shared-types/node_modules ./packages/shared-types/node_modules
COPY --from=deps /app/packages/validators/node_modules ./packages/validators/node_modules
COPY pnpm-lock.yaml pnpm-workspace.yaml package.json turbo.json tsconfig.base.json ./
COPY backend backend
COPY packages packages
RUN pnpm --filter @payspin/shared-types build \
  && pnpm --filter @payspin/pisp-provider build \
  && pnpm --filter @payspin/validators build \
  && cd backend && pnpm exec prisma generate \
  && pnpm --filter @payspin/backend build

FROM node:20-alpine AS runner
RUN apk add --no-cache openssl libc6-compat \
  && npm install -g prisma@6.1.0
WORKDIR /app
ENV NODE_ENV=production
# Keep monorepo node_modules layout so pnpm symlinks resolve.
COPY --from=build /app ./
WORKDIR /app/backend
COPY backend/docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
EXPOSE 3001
ENTRYPOINT ["/entrypoint.sh"]
CMD ["node", "dist/main.js"]
