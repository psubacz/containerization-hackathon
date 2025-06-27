# =============================================================================
# Multi-architecture Go Application Dockerfile
# Cross-platform build supporting multiple CPU architectures
# =============================================================================

FROM --platform=$BUILDPLATFORM golang:1.21-alpine AS builder

# Install cross-compilation tools
RUN apk add --no-cache git ca-certificates

WORKDIR /app

# Copy go module files and download dependencies
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build arguments for cross-compilation
ARG TARGETOS
ARG TARGETARCH

# Build for target architecture
RUN CGO_ENABLED=0 \
    GOOS=${TARGETOS:-linux} \
    GOARCH=${TARGETARCH:-amd64} \
    go build \
    -a -installsuffix cgo \
    -ldflags='-w -s -extldflags "-static"' \
    -o main .

# =============================================================================
# Final stage - minimal runtime with multi-arch support
# =============================================================================
FROM --platform=$TARGETPLATFORM alpine:3.18

# Install runtime dependencies and create user
RUN apk --no-cache add ca-certificates tzdata wget \
    && addgroup -g 1001 -S appgroup \
    && adduser -u 1001 -S appuser -G appgroup

WORKDIR /app

# Copy binary from builder
COPY --from=builder /app/main .

# Set ownership and permissions
RUN chown appuser:appgroup main && chmod +x main

# Switch to non-root user
USER appuser:appgroup

# Expose port (consistent with application)
EXPOSE 8080

# Add metadata
LABEL \
    org.opencontainers.image.title="Gin Web Server (Multi-arch)" \
    org.opencontainers.image.description="Multi-architecture Go web server" \
    org.opencontainers.image.vendor="Custom Build"

# Health check using application endpoint
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# Run the application
ENTRYPOINT ["./main"]
