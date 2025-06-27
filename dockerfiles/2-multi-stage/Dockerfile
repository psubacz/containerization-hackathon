# =============================================================================
# Multi-stage Build for Go Application
# Multiple stages for optimization: deps, build, runtime, and development
# =============================================================================

# Stage 1: Build dependencies and tools
FROM golang:1.21-alpine AS deps

# Install essential tools
RUN apk add --no-cache git ca-certificates tzdata

WORKDIR /app

# Copy and download dependencies
COPY go.mod go.sum ./
RUN go mod download

# =============================================================================
# Stage 2: Build the application
# =============================================================================
FROM deps AS builder

# Copy source code
COPY . .

# Build with optimizations
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags='-w -s -extldflags "-static"' \
    -a -installsuffix cgo \
    -o main .

# =============================================================================
# Stage 3: Runtime image with minimal Alpine
# =============================================================================
FROM alpine:3.18 AS runtime

# Install runtime dependencies and create user
RUN apk --no-cache add ca-certificates tzdata wget \
    && addgroup -g 1001 -S appgroup \
    && adduser -u 1001 -S appuser -G appgroup

WORKDIR /app

# Copy binary from builder
COPY --from=builder /app/main .

# Set ownership and switch to non-root user
RUN chown appuser:appgroup main
USER appuser:appgroup

# Expose port (consistent with application)
EXPOSE 8080

# Add metadata
LABEL \
    org.opencontainers.image.title="Gin Web Server (Multi-stage)" \
    org.opencontainers.image.description="Multi-stage build Go web server"

# Health check using application endpoint
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# Run the application
ENTRYPOINT ["./main"]

# =============================================================================
# Stage 4: Development stage (optional)
# =============================================================================
FROM golang:1.21-alpine AS development

# Install development tools
RUN apk add --no-cache git ca-certificates

WORKDIR /app

# Copy dependencies
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Expose port
EXPOSE 8080

# Add metadata
LABEL \
    org.opencontainers.image.title="Gin Web Server (Development)" \
    org.opencontainers.image.description="Development build with live reload"

# Development command
CMD ["go", "run", "main.go"]
