# Payspin Ops portal UI — production image (monorepo root context)
FROM node:20-alpine AS base
RUN apk add --no-cache libc6-compat \
  && corepack enable \
  && corepack prepare pnpm@9.15.0 --activate
WORKDIR /app

FROM base AS deps
COPY pnpm-lock.yaml pnpm-workspace.yaml package.json ./
COPY ops-portal/frontend/package.json ops-portal/frontend/
COPY packages/shared-types/package.json packages/shared-types/
COPY packages/validators/package.json packages/validators/
RUN pnpm install --frozen-lockfile

FROM base AS build
ARG NEXT_PUBLIC_OPS_API_URL=https://ops.payspin.io/admin/v1
ARG NEXT_PUBLIC_PAYER_WEB_URL=https://pay.payspin.io
ENV NEXT_PUBLIC_OPS_API_URL=$NEXT_PUBLIC_OPS_API_URL
ENV NEXT_PUBLIC_PAYER_WEB_URL=$NEXT_PUBLIC_PAYER_WEB_URL
ENV NEXT_TELEMETRY_DISABLED=1
COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/ops-portal/frontend/node_modules ./ops-portal/frontend/node_modules
COPY --from=deps /app/packages/shared-types/node_modules ./packages/shared-types/node_modules
COPY pnpm-lock.yaml pnpm-workspace.yaml package.json tsconfig.base.json ./
COPY packages/shared-types packages/shared-types
COPY packages/validators packages/validators
COPY ops-portal/frontend ops-portal/frontend
RUN pnpm --filter @payspin/shared-types build \
  && pnpm --filter @payspin/ops-frontend build

FROM node:20-alpine AS runner
RUN apk add --no-cache wget
WORKDIR /app
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=3003
ENV HOSTNAME=0.0.0.0
COPY --from=build /app/ops-portal/frontend/.next/standalone ./
COPY --from=build /app/ops-portal/frontend/.next/static ./ops-portal/frontend/.next/static
COPY --from=build /app/ops-portal/frontend/public ./ops-portal/frontend/public
USER node
EXPOSE 3003
HEALTHCHECK --interval=15s --timeout=5s --retries=5 --start-period=20s \
  CMD wget -qO- http://127.0.0.1:3003/login >/dev/null 2>&1 || exit 1
CMD ["node", "ops-portal/frontend/server.js"]
