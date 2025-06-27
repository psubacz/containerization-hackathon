# =============================================================================
# Minimal Go Application using Scratch Base
# Two-stage build for minimal final image size
# =============================================================================

FROM golang:1.21-alpine AS builder

# Install ca-certificates for HTTPS requests
RUN apk --no-cache add ca-certificates git tzdata

# Create non-root user
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

WORKDIR /app

# Copy go module files and download dependencies
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build static binary
RUN CGO_ENABLED=0 GOOS=linux go build \
    -a -installsuffix cgo \
    -ldflags='-w -s -extldflags "-static"' \
    -o main .

# =============================================================================
# Final stage - scratch image (smallest possible)
# =============================================================================
FROM scratch

# Copy timezone data and certificates from builder
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group

# Copy binary from builder
COPY --from=builder /app/main /main

# Use non-root user
USER appuser:appgroup

# Expose port (consistent with application)
EXPOSE 8080

# Add metadata
LABEL \
    org.opencontainers.image.title="Gin Web Server (Minimal)" \
    org.opencontainers.image.description="Minimal Go web server using scratch base"

# Run the application
ENTRYPOINT ["/main"]
