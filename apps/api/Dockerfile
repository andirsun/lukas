# Development image for the API. Build from the repository root:
#   docker compose build api
FROM node:22-alpine
WORKDIR /repo
RUN corepack enable

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY packages/core/package.json packages/core/
COPY packages/db/package.json packages/db/
COPY packages/importers/package.json packages/importers/
COPY apps/api/package.json apps/api/
RUN pnpm install --frozen-lockfile --filter "@lukas/api..."

COPY tsconfig.base.json ./
COPY docker docker
COPY packages packages
COPY apps/api apps/api

EXPOSE 3000
CMD ["pnpm", "--filter", "@lukas/api", "start"]
