# Stage 1: Build
FROM node:18-alpine AS builder
WORKDIR /app
COPY app/package.json app/package-lock.json ./
RUN npm ci --maxsockets=2
COPY app/ ./
RUN npm test

# Stage 2: Production
FROM node:18-alpine AS production
LABEL maintainer="Satvik"
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
WORKDIR /app
COPY app/package.json app/package-lock.json ./
RUN npm ci --omit=dev --maxsockets=2
COPY app/src ./src
RUN chown -R appuser:appgroup /app
USER appuser
EXPOSE 3000
ENV NODE_ENV=production
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1
CMD ["node", "src/index.js"]
