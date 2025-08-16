# Stage 1: Build
FROM node:20.11-alpine3.18 AS build

# Install required build tools
RUN apk add --no-cache python3 make g++ git

# Enable pnpm via corepack
RUN corepack enable

WORKDIR /app

# Copy dependency manifests first (for better caching)
COPY service/package.json service/pnpm-lock.yaml ./

# Install dependencies (production only, lockfile respected)
RUN pnpm install --production --frozen-lockfile

# Copy application source
COPY service/ ./

# Stage 2: Runtime (slim image)
FROM node:20.11-alpine3.18

# Install dumb-init to handle PID 1 & signals
RUN apk add --no-cache dumb-init

WORKDIR /app

# Copy built node_modules + source from build stage
COPY --from=build /app /app

EXPOSE 3000

ENV NODE_ENV=production
ENV PDS_PORT=3000
# Disable io_uring for Node perf issues on Alpine
ENV UV_USE_IO_URING=0

ENTRYPOINT ["dumb-init", "--"]

CMD ["node", "--enable-source-maps", "index.js"]

LABEL org.opencontainers.image.source="https://github.com/Next-House-Org/pds"
LABEL org.opencontainers.image.description="AT Protocol PDS"
LABEL org.opencontainers.image.licenses="MIT"

