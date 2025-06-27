# Docker Build Examples for Gin Web Server

This directory contains progressive examples of Dockerfiles for a Go web server, demonstrating various optimization techniques and best practices.

## File Structure

```
dockerfiles/
├── 0-simple/                     # Basic single-stage build
├── 1-minimal/                    # Multi-stage with minimal base images
├── 2-multi-stage/                # Advanced multi-stage optimization
├── 3-multi-arch/                 # Multi-architecture support
└── 4-minimal-multistage-multiarch/  # All optimizations combined
```

## Build Examples

### 0. Simple Build (Development/Learning)
**Best for**: Development, learning Docker basics
**Image Size**: ~300MB+

```bash
cd dockerfiles/0-simple
docker build -t gin-webserver:simple .
```

### 1. Minimal Builds (Production)
**Best for**: Production deployments prioritizing small image size
**Image Size**: ~2-10MB

#### Scratch-based (Ultra-minimal)
```bash
cd dockerfiles/1-minimal
docker build -t gin-webserver:minimal .
```

#### Distroless-based (Secure minimal)
```bash
cd dockerfiles/1-minimal
docker build -f Dockerfile.distroless -t gin-webserver:distroless .
```

### 2. Multi-stage Build (Optimized Development)
**Best for**: Optimized builds with development capabilities
**Image Size**: ~20-50MB

```bash
cd dockerfiles/2-multi-stage
# Production build
docker build --target runtime -t gin-webserver:multi-stage .
# Development build
docker build --target development -t gin-webserver:dev .
```

### 3. Multi-architecture Build (Cross-platform)
**Best for**: Deploying to different CPU architectures
**Image Size**: ~20-50MB

```bash
cd dockerfiles/3-multi-arch
# Build for current platform
docker build -t gin-webserver:multi-arch .

# Build for specific platform
docker build --platform linux/arm64 -t gin-webserver:arm64 .

# Multi-platform build and push
docker buildx build \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  -t your-registry/gin-webserver:latest \
  --push .
```

### 4. Combined Optimizations (Production Ready)
**Best for**: Production deployments requiring all optimizations
**Image Size**: ~2-10MB

```bash
cd dockerfiles/4-minimal-multistage-multiarch

# Default build (distroless)
docker build -t gin-webserver:optimized .

# Ultra-minimal (scratch)
docker build --target runtime-scratch -t gin-webserver:scratch .

# Development
docker build --target development -t gin-webserver:dev .

# Multi-platform production build
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t your-registry/gin-webserver:latest \
  --push .
```

## Key Concepts Demonstrated

### 1. Single vs Multi-stage Builds
- **Single-stage**: Simple but includes build tools in final image
- **Multi-stage**: Separates build and runtime, reducing final image size

### 2. Base Image Selection
- **golang:alpine**: Full Go environment (~300MB+)
- **alpine**: Minimal Linux with package manager (~20-50MB)
- **distroless**: Google's minimal runtime (~5-10MB)
- **scratch**: Empty base image (~2-5MB)

### 3. Multi-architecture Support
- Uses `--platform=$BUILDPLATFORM` for build stage
- Uses `--platform=$TARGETPLATFORM` for runtime stage
- Supports AMD64, ARM64, ARMv7 architectures

### 4. Security Best Practices
- Non-root user execution
- Static binary compilation
- Minimal attack surface
- No unnecessary packages

### 5. Optimization Techniques
- Build cache optimization
- Layer minimization
- Static linking
- Binary stripping (`-ldflags='-w -s'`)

## Size Comparison

| Build Type | Image Size | Security | Complexity | Use Case |
|------------|------------|----------|------------|----------|
| Simple | ~300MB | Medium | Low | Development |
| Minimal (scratch) | ~2-5MB | High | Medium | Production |
| Minimal (distroless) | ~5-10MB | Very High | Medium | Production |
| Multi-stage | ~20-50MB | High | Medium | Balanced |
| Multi-arch | ~20-50MB | High | High | Cross-platform |
| Combined | ~2-10MB | Very High | High | Enterprise |

## Running the Containers

All containers expose port 8080 and include health checks:

```bash
# Run any variant
docker run -p 8080:8080 gin-webserver:TAG

# Test the server
curl http://localhost:8080
curl http://localhost:8080/health
curl http://localhost:8080/user/john

# Check health
docker ps  # STATUS should show "healthy"
```

## Development Workflow

For active development, use the development targets:

```bash
# Multi-stage development
docker build --target development -t gin-webserver:dev dockerfiles/2-multi-stage
docker run -p 8080:8080 -v $(pwd):/app gin-webserver:dev

# Combined development
docker build --target development -t gin-webserver:dev dockerfiles/4-minimal-multistage-multiarch
docker run -p 8080:8080 -v $(pwd):/app gin-webserver:dev
```

## Best Practices Applied

1. **Layer Caching**: Dependencies downloaded before copying source code
2. **Security**: Non-root users, minimal base images
3. **Size Optimization**: Multi-stage builds, static linking
4. **Maintainability**: Clear stage naming, comprehensive comments
5. **Flexibility**: Multiple runtime options, development targets
6. **Standards**: OCI image labels, consistent port exposure
7. **Health Monitoring**: Built-in health checks

## Troubleshooting

### Common Issues

1. **Binary not found**: Ensure static linking with CGO_ENABLED=0
2. **Permission denied**: Check user permissions and binary executable bit
3. **Health check fails**: Verify the /health endpoint is accessible
4. **Cross-compilation errors**: Verify TARGETOS/TARGETARCH are set correctly

### Debugging Commands

```bash
# Check image layers
docker history gin-webserver:TAG

# Inspect image
docker inspect gin-webserver:TAG

# Run with shell (for Alpine-based images)
docker run -it --entrypoint /bin/sh gin-webserver:TAG

# Check binary properties
docker run --rm gin-webserver:TAG file /main
```

Choose the appropriate Dockerfile based on your specific requirements for image size, security, and deployment complexity.
