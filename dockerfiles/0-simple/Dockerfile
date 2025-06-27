# =============================================================================
# Simple Go Application Dockerfile
# Basic single-stage build suitable for development and learning
# =============================================================================

FROM golang:1.21-alpine

# Install ca-certificates for HTTPS requests
RUN apk add --no-cache ca-certificates git

# Set working directory
WORKDIR /app

# Copy go module files and download dependencies
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN go build -o main .

# Expose port (consistent with application)
EXPOSE 8080

# Add basic metadata
LABEL \
    org.opencontainers.image.title="Gin Web Server (Simple)" \
    org.opencontainers.image.description="Simple single-stage Go web server build"

# Run the application
CMD ["./main"]
