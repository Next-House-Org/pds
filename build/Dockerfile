# Stage 1: Build
FROM node:20-alpine AS builder

WORKDIR /app

# Install dependencies
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

# Copy source code
COPY . .

# Compile TypeScript
RUN yarn build

# Stage 2: Runtime
FROM node:20-alpine AS runner
WORKDIR /app

# Copy only runtime files
COPY --from=builder /app ./

# Expose the port (adjust if different in config.ts)
EXPOSE 3000

ENV NODE_ENV=production

# Run the service
CMD ["node", "dist/index.js"]

