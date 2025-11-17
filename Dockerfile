# Stage 1: Dependency Installation & Build (Multi-stage)
FROM node:22-alpine AS builder

# Install libc6-compat for Next.js on Alpine Linux
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Copy lock/package files and install dependencies
COPY package.json package-lock.json ./
RUN npm ci --prefer-offline --no-audit

# Copy source code and build
COPY . .
ENV NEXT_TELEMETRY_DISABLED 1
RUN npm run build

# Stage 2: Production Image (The efficient runner)
# Use a minimal base image that only includes the necessary runtime.
FROM node:22-alpine AS runner

# Install libc6-compat for Next.js on Alpine Linux
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Set environment variables
ENV NODE_ENV production
# Cloud Run automatically sets the PORT env var (usually 8080), 
# but Next.js expects the start script to handle it.
ENV PORT 8080 
EXPOSE 8080

# --- CRITICAL CHANGE: Copy Standalone Output ---
# The standalone output creates a self-contained server in .next/standalone/
# It traces *only* the necessary node_modules, removing the need for 'npm prune'.
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public

# Set a non-root user for security (required by some organizations)
# The user 'nextjs' is created in the previous Cloud Run example.
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs
USER nextjs

# The command to run the built standalone server
CMD ["node", "server.js"]