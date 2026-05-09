# Traffic AI Dockerfile - Go Application
ARG GO_VERSION=1.23-alpine
FROM golang:${GO_VERSION} AS base
RUN apk add --no-cache git openssh-client curl make
WORKDIR /app

# Builder stage - clone and build
FROM base AS builder
ARG GIT_REPO
ARG GIT_BRANCH=main
ARG GIT_TOKEN
ARG BUILD_TARGET=control
ARG CACHEBUST=1

# Clone repository (CACHEBUST from update.sh forces re-clone for new branch)
RUN echo "Cache bust: ${CACHEBUST}" && \
    rm -rf /app/* /app/.* 2>/dev/null || true && \
    if [ -n "$GIT_TOKEN" ]; then \
      git clone --depth 1 --branch ${GIT_BRANCH} \
        https://${GIT_TOKEN}@${GIT_REPO#https://} . ; \
    else \
      git clone --depth 1 --branch ${GIT_BRANCH} ${GIT_REPO} . ; \
    fi

# Build Go binaries - allow toolchain auto-download
ENV GOTOOLCHAIN=auto
ENV GOPROXY=https://goproxy.cn,direct
RUN go mod download
RUN if [ "$BUILD_TARGET" = "control" ]; then \
      go build -ldflags="-s -w" -o /app/bin/control ./cmd/control ; \
    elif [ "$BUILD_TARGET" = "gateway" ]; then \
      go build -ldflags="-s -w" -o /app/bin/gateway ./cmd/gateway ; \
    fi

# Production stage
FROM alpine:latest AS production
WORKDIR /app

# Install runtime dependencies
RUN apk add --no-cache ca-certificates tzdata curl

# Copy binary and configs
COPY --from=builder /app/bin/ ./bin/
COPY --from=builder /app/configs/ ./configs/

ARG BUILD_TARGET=control
ENV BUILD_TARGET=${BUILD_TARGET}

EXPOSE 18080 8083 8081

CMD if [ "$BUILD_TARGET" = "gateway" ]; then \
      ./bin/gateway -config ./configs/config.yaml; \
    else \
      ./bin/control -config ./configs/config.yaml; \
    fi
