# Payspin payer web — production image (monorepo root context)
FROM node:20-alpine AS base
RUN apk add --no-cache libc6-compat \
  && corepack enable \
  && corepack prepare pnpm@9.15.0 --activate
WORKDIR /app

FROM base AS deps
COPY pnpm-lock.yaml pnpm-workspace.yaml package.json ./
COPY frontend/package.json frontend/
COPY packages/shared-types/package.json packages/shared-types/
COPY packages/validators/package.json packages/validators/
COPY packages/pisp-provider/package.json packages/pisp-provider/
RUN pnpm install --frozen-lockfile

FROM base AS build
# Public API base URL is inlined into the client bundle at build time.
ARG NEXT_PUBLIC_API_URL=http://localhost:3001/v1
ENV NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL
ENV NEXT_TELEMETRY_DISABLED=1
COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/frontend/node_modules ./frontend/node_modules
COPY --from=deps /app/packages/shared-types/node_modules ./packages/shared-types/node_modules
COPY pnpm-lock.yaml pnpm-workspace.yaml package.json turbo.json tsconfig.base.json ./
COPY packages packages
COPY frontend frontend
RUN pnpm --filter @payspin/shared-types build \
  && pnpm --filter @payspin/frontend build

FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=3000
# Standalone output is rooted at the monorepo (outputFileTracingRoot).
COPY --from=build /app/frontend/.next/standalone ./
COPY --from=build /app/frontend/.next/static ./frontend/.next/static
COPY --from=build /app/frontend/public ./frontend/public
USER node
EXPOSE 3000
CMD ["node", "frontend/server.js"]
