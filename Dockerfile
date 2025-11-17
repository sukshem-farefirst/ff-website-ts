# Stage 2: Production Image (The traditional runner)
FROM node:22-alpine AS runner

# Install compatibility package for Next.js on Alpine
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Set environment variables
ENV NODE_ENV production
ENV PORT 8080
EXPOSE 8080

# Copying Standard Next.js Output
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules 
COPY --from=builder /app/public ./public 
COPY --from=builder /app/package.json ./package.json # Keep this for 'npm start'

# Set a non-root user for security
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs
USER nextjs

CMD ["npm", "start"]