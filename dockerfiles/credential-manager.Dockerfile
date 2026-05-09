# Credential Manager Dockerfile - Go Application

# Builder stage
FROM docker.1ms.run/library/golang:1.23-alpine AS builder
RUN apk add --no-cache git openssh-client curl
WORKDIR /app
ARG GIT_REPO
ARG GIT_BRANCH=main
ARG GIT_TOKEN
ARG CACHEBUST=1

# Clone repository (CACHEBUST forces refresh)
RUN echo "Cache bust: ${CACHEBUST}" && \
    rm -rf /app/* /app/.* 2>/dev/null || true && \
    if [ -n "$GIT_TOKEN" ]; then \
      git clone --depth 1 --branch ${GIT_BRANCH} \
        https://${GIT_TOKEN}@${GIT_REPO#https://} . ; \
    else \
      git clone --depth 1 --branch ${GIT_BRANCH} ${GIT_REPO} . ; \
    fi

# Build binary - allow toolchain auto-download
ENV GOTOOLCHAIN=auto
# 新增这一行，放在FROM之前/之后都可以
ENV GOPROXY=https://goproxy.cn,direct
RUN go mod download
RUN go build -ldflags="-s -w" -o /app/claw-vault-server ./cmd/server

# Web UI builder stage
FROM docker.1ms.run/library/node:20-alpine AS web-builder
WORKDIR /web
COPY --from=builder /app/web/package*.json ./
RUN npm install --production
COPY --from=builder /app/web ./

# Production stage
FROM docker.1ms.run/library/alpine:latest AS production
WORKDIR /app

# Install runtime dependencies including Node.js for web UI and bash for scripts
RUN apk add --no-cache ca-certificates tzdata nodejs npm bash

# Copy binary
COPY --from=builder /app/claw-vault-server ./claw-vault-server

# Copy web UI
COPY --from=web-builder /web ./web

# Copy scripts
COPY --from=builder /app/scripts ./scripts

ENV VAULT_PATH=/vault
ENV CLAW_VAULT_PASSWORD=""
ENV WEB_PORT=8080
ENV API_BASE=http://127.0.0.1:8002

VOLUME /vault
EXPOSE 8002 8080

# Start both API server and Web UI
CMD sh -c './claw-vault-server -config /app/config/config.yaml & cd web && node standalone-server.js'
