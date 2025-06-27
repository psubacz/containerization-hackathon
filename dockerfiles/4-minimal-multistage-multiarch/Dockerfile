# =============================================================================
# Minimal + Multi-Stage + Multi-Architecture Dockerfile
# Combines optimization strategies: minimal image size, multi-stage builds, 
# and multi-architecture support
# =============================================================================

# =============================================================================
# Stage 1: Dependency preparation and tools
# =============================================================================
FROM --platform=$BUILDPLATFORM golang:1.23-alpine AS deps

# Install essential build tools and certificates
RUN apk add --no-cache \
    git \
    ca-certificates \
    tzdata \
    file

# Create non-root user for security
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

WORKDIR /app

# Copy and download dependencies
COPY go.mod go.sum ./
RUN go mod download && go mod verify

# =============================================================================
# Stage 2: Build stage with cross-compilation support
# =============================================================================
FROM deps AS builder

# Build arguments for multi-architecture support
ARG TARGETOS
ARG TARGETARCH

# Copy source code
COPY . .

# Build optimized static binary for target architecture
RUN CGO_ENABLED=0 \
    GOOS=${TARGETOS:-linux} \
    GOARCH=${TARGETARCH:-amd64} \
    go build \
    -a \
    -installsuffix cgo \
    -ldflags='-w -s -extldflags "-static"' \
    -tags netgo \
    -trimpath \
    -o main .

# Binary built successfully - static linking enabled

# =============================================================================
# Stage 3: Minimal runtime - Distroless (default and recommended)
# =============================================================================
FROM gcr.io/distroless/static:nonroot AS runtime-distroless

# Copy the binary
COPY --from=builder /app/main /main

# Expose port (consistent with application)
EXPOSE 8080

# Add image metadata
LABEL \
    org.opencontainers.image.title="Gin Web Server" \
    org.opencontainers.image.description="Minimal multi-arch Go web server using Gin framework" \
    org.opencontainers.image.vendor="Custom Build" \
    org.opencontainers.image.version="1.0" \
    org.opencontainers.image.source="https://github.com/example/gin-webserver"

# Health check using application endpoint
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ["/main", "-check"] || exit 1

# Run the application (distroless runs as nonroot by default)
ENTRYPOINT ["/main"]

# =============================================================================
# Stage 4: Minimal runtime - Scratch (ultra-minimal alternative)
# =============================================================================
FROM scratch AS runtime-scratch

# Copy timezone data and certificates
COPY --from=deps /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=deps /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=deps /etc/passwd /etc/passwd
COPY --from=deps /etc/group /etc/group

# Copy the binary
COPY --from=builder /app/main /main

# Use non-root user
USER appuser:appgroup

# Expose port
EXPOSE 8080

# Add image metadata
LABEL \
    org.opencontainers.image.title="Gin Web Server (Scratch)" \
    org.opencontainers.image.description="Ultra-minimal multi-arch Go web server" \
    org.opencontainers.image.vendor="Custom Build"

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ["/main", "-check"] || exit 1

# Run the application
ENTRYPOINT ["/main"]

# =============================================================================
# Stage 5: Development runtime (for local development)
# =============================================================================
FROM --platform=$BUILDPLATFORM golang:1.23-alpine AS development

# Install development tools
RUN apk add --no-cache \
    bash \
    curl \
    git \
    ca-certificates

WORKDIR /app

# Copy go mod files and download dependencies
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Expose port
EXPOSE 8080

# Development command with live reloading
CMD ["go", "run", "main.go"]

