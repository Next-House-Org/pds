# Stage 1: Build
FROM node:20.11-alpine3.18 AS build

# Install build tools
RUN apk add --no-cache python3 make g++ git

# Enable pnpm
RUN corepack enable

WORKDIR /app

# Copy dependency files for caching
COPY service/package.json service/pnpm-lock.yaml ./

# Install dependencies (production only)
RUN pnpm install --production --frozen-lockfile

# Copy source code
COPY service/ ./

# Copy pdsadmin scripts for build stage (optional if needed in build)
COPY pdsadmin/ ./pdsadmin/
COPY pdsadmin.sh ./

# Ensure all scripts are executable
RUN chmod +x pdsadmin.sh && chmod +x pdsadmin/*

# Stage 2: Runtime (slim image)
FROM node:20.11-alpine3.18

# Install required runtime tools
RUN apk add --no-cache \
    dumb-init \
    curl \
    openssl \
    coreutils \
    vim bash git

WORKDIR /app

# Copy built node_modules + source from build stage
COPY --from=build /app /app

# Set environment
ENV NODE_ENV=production
ENV PDS_PORT=3000
ENV UV_USE_IO_URING=0

EXPOSE 3000

ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "--enable-source-maps", "index.js"]

LABEL org.opencontainers.image.source="https://github.com/Next-House-Org/pds"
LABEL org.opencontainers.image.description="AT Protocol PDS"
LABEL org.opencontainers.image.licenses="MIT"

