# Stage 1: Dependency Installation & Build
FROM node:22-alpine AS builder

# Install compatibility package for Next.js on Alpine
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Copy lock/package files and install dependencies
COPY package.json package-lock.json ./
RUN npm ci --prefer-offline --no-audit

# Copy source code and build
COPY . .
ENV NEXT_TELEMETRY_DISABLED 1
RUN npm run build
# We'll keep the full node_modules and .next directory for the runner stage

# ----------------------------------------------------

# Stage 2: Production Image (The traditional runner)
FROM node:22-alpine AS runner

# Install compatibility package for Next.js on Alpine
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Set environment variables
ENV NODE_ENV production
ENV PORT 8080
EXPOSE 8080

# --- CRITICAL CHANGE: Copying Standard Next.js Output ---
# 1. Copy necessary files for the Next.js server to run.
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules 
COPY --from=builder /app/package.json ./package.json 
COPY --from=builder /app/public ./public 
COPY --from=builder /app/next.config.mjs ./next.config.mjs # Include config if necessary

# Set a non-root user for security
# The user 'nextjs' is created here.
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs
USER nextjs

# The command to run the built Next.js server
# It will use the PORT environment variable (8080)
CMD ["npm", "start"]