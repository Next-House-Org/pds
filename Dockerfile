# =========================
# Build stage
# =========================
FROM node:20.11-alpine3.18 AS build

# Enable pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

# System deps
RUN apk add --no-cache python3 make g++ git

WORKDIR /app

# --- Copy files needed for a deterministic install & better caching
COPY pnpm-lock.yaml pnpm-workspace.yaml package.json ./
COPY tsconfig ./tsconfig

# Copy package.json files (speeds up cache for install)
# If your repo includes other packages, list them here too.
COPY packages ./packages
COPY services ./services
COPY lexicons ./lexicons

# Install ALL deps across the workspace (we need dev deps to build CLI/dist)
RUN pnpm install --frozen-lockfile

# Build the entire workspace (compiles TS to dist for all packages)
RUN pnpm -w build


# =========================
# Runtime stage
# =========================
FROM node:20.11-alpine3.18

# dumb-init for proper signal handling
RUN apk add --no-cache dumb-init curl

WORKDIR /app

# Copy compiled workspace and node_modules from build
COPY --from=build /app /app

# Helpful wrappers
# pds -> run the server
# pds-admin -> run admin/maintenance commands, e.g.:
#   pds-admin admin:create-invite
#   pds-admin db:migrate
RUN printf '%s\n' \
  '#!/bin/sh' \
  'exec node --enable-source-maps /app/services/pds/index.js "$@"' \
  > /usr/local/bin/pds && chmod +x /usr/local/bin/pds \
  && printf '%s\n' \
  '#!/bin/sh' \
  'exec node /app/services/pds/run-script.js "$@"' \
  > /usr/local/bin/pds-admin && chmod +x /usr/local/bin/pds-admin

# Default ports the PDS uses:
# - 2583: public ATProto XRPC
# - 3000: (often internal/admin/metrics depending on config)
EXPOSE 2583 3000

# Common envs (override at runtime with docker-compose)
ENV NODE_ENV=production \
    UV_USE_IO_URING=0 \
    PDS_PORT=2583

# Basic healthcheck (adjust the path if your build exposes a different health route)
HEALTHCHECK --interval=30s --timeout=5s --retries=5 CMD \
  curl -fsS http://127.0.0.1:2583/xrpc/_health || exit 1

ENTRYPOINT ["dumb-init", "--"]
CMD ["pds"]

# Labels
LABEL org.opencontainers.image.title="AT Protocol PDS" \
      org.opencontainers.image.description="All-in-one PDS build with admin CLI" \
      org.opencontainers.image.licenses="MIT"

