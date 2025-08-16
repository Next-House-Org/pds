# Use lightweight Node.js base image
FROM node:20.11-alpine3.18 AS build

# Install build dependencies
RUN apk add --no-cache python3 make g++ git

WORKDIR /app

# Copy only dependency files first for caching
COPY package.json pnpm-lock.yaml* ./

# Setup pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy the rest of the source code
COPY . .

# Build the project (if build step exists)
RUN pnpm run build || echo "No build step defined"

# ---- Runtime stage ----
FROM node:20.11-alpine3.18

WORKDIR /app

# Copy node_modules and build artifacts from build stage
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY --from=build /app/package.json ./package.json

# Expose PDS default port
EXPOSE 3000

# Default command (can be overridden by docker-compose / k8s)
CMD ["pnpm", "start"]

