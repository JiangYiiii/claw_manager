# Plugin Manager Dockerfile - Node.js Application
ARG NODE_VERSION=20-alpine
FROM node:${NODE_VERSION} AS base
RUN apk add --no-cache git openssh-client curl
WORKDIR /app

# Builder stage
FROM base AS builder
ARG GIT_REPO
ARG GIT_BRANCH=main
ARG GIT_TOKEN

# Bust cache to force re-clone when source repo updates
ARG CACHEBUST=1

# Clone repository (CACHEBUST from update.sh forces re-clone)
RUN echo "Cache bust: ${CACHEBUST}" && \
    rm -rf /app/* /app/.* 2>/dev/null || true && \
    if [ -n "$GIT_TOKEN" ]; then \
      git clone --depth 1 --branch ${GIT_BRANCH} \
        https://${GIT_TOKEN}@${GIT_REPO#https://} . ; \
    else \
      git clone --depth 1 --branch ${GIT_BRANCH} ${GIT_REPO} . ; \
    fi

# Install dependencies
RUN npm install --production

# Production stage
FROM node:${NODE_VERSION} AS production
WORKDIR /app

# Install runtime deps for MCP sidecars
RUN apk add --no-cache \
    tzdata \
    python3 \
    py3-pip \
    ffmpeg \
    yt-dlp

# Copy dependencies and code
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/src ./src
COPY --from=builder /app/config ./config
COPY --from=builder /app/mcp-servers ./mcp-servers

# Install Python deps for douyin-analyzer sidecar
RUN python3 -m venv /opt/douyin-analyzer-venv && \
    /opt/douyin-analyzer-venv/bin/pip install --no-cache-dir --upgrade pip setuptools wheel && \
    /opt/douyin-analyzer-venv/bin/pip install --no-cache-dir -r /app/mcp-servers/douyin-analyzer/requirements.txt

ENV NODE_ENV=production
ENV TZ=Asia/Shanghai
EXPOSE 9000 8090

CMD ["node", "src/index.js", "--config", "config/config.yaml"]
