# Contianer Demo

This repo demonstrates

Inside you will find:

- a golang Gin Web Server for testing
- a series of dockerfiles to demonstrates different ways to build a container
- a helm chart for demo purposes
- a skaffold

>　Notice: this repo was build with the assistance of [claude](https://claude.ai/).

## Prereqs

- [golang] (https://go.dev/dl/)
- contianer builder
  - [Buildah](https://buildah.io/gettingstarted.html)
  - [podman](https://podman.io/docs/installation)
  - [docker](https://docs.docker.com/engine/install/)

## Directory Structure

Container Example

```
dockerfiles/
├── simple/          # Basic Dockerfile
├── minimal/         # Minimal image builds (scratch & distroless)
├── multi-stage/     # Multi-stage builds
├── multi-arch/      # Multi-architecture builds
├── build-all.sh     # Build all variants
└── README.md        # This file
```

A basic Go web server built with the Gin framework.

## Setup - local golang development

1. Make sure you have Go installed (version 1.21 or later)
2. Navigate to the project directory

### Install dependencies:

   ```bash
   go mod tidy
   ```

### Running the Server

```bash
go run main.go
```

The server will start on port 8080.

### Available Endpoints

- `GET /` - Basic hello world response
- `GET /user/:name` - Greets a specific user (replace :name with actual name)
- `GET /search?q=query&limit=10` - Search endpoint with query parameters
- `POST /data` - Accepts JSON data in request body
- `GET /health` - Health check endpoint

### Example Usage

```bash
# Basic request
curl http://localhost:8080/

# User greeting
curl http://localhost:8080/user/john

# Search with parameters
curl "http://localhost:8080/search?q=golang&limit=5"

# POST JSON data
curl -X POST http://localhost:8080/data \
  -H "Content-Type: application/json" \
  -d '{"name": "test", "value": 123}'

# Health check
curl http://localhost:8080/health
```

## Containerize

This project demonstrates progressive containerization techniques for applications, from basic to advanced optimization strategies. Each approach builds upon the previous one, showcasing different aspects of container optimization.

> Note:
> - these example use containers for building and running the software
> - Docker is used in this example, podman, kaniko, and buildah should be interchangable here (not tested)
> - the docker flag `--load` is used to export to local docker repo. In CI/CD change to push and ensure your reporsitoy name is set correctly.

### Simple
Basic containerization approach for learning and development
> Location: `dockerfiles/0-simple/Dockerfile`  

This is the most straightforward way to containerize an application. It uses the full Go development image as the base and includes all build tools in the final container.

**Characteristics:**

- Uses `golang:1.21-alpine` as the base image
- Includes the entire Go toolchain in the final image
- Simple single-stage build process
- Larger image size (~300MB+)
- Good for development and learning

**Build and run:**

```bash
# Build the image
docker build -f ./dockerfiles/0-simple/Dockerfile -t gin-webserver:simple .  --load

# Run the container
docker run -p 8080:8080 gin-webserver:simple

# Test the application
curl http://localhost:8080/health
```

When to use:

- Development environments
- learning Docker basics
- rapid prototyping

### Minimal

Reduce image size and attack surface using minimal base images

> Location: `dockerfiles/1-minimal/Dockerfile` and `dockerfiles/1-minimal/Dockerfile.distroless`
> Note: This approach focuses on creating the smallest possible production images by using minimal base images like `scratch` or `distroless`.

**Two variants available:**

#### Scratch-based (Dockerfile)

- Uses `scratch` as the base image (0 bytes - no rebuild layers)
- Includes only essential SSL certificates
- Produces ultra-minimal images (~10-15MB)
- Statically linked binary

#### Distroless-based (Dockerfile.distroless)

- Uses Google's distroless images
- Includes minimal runtime dependencies
- Better security with non-root user
- Slightly larger but more secure (~20-25MB)

**Build and run:**

```bash
# Build scratch-based minimal image
docker build -f dockerfiles/1-minimal/Dockerfile -t gin-webserver:minimal-scratch . --load

# Build distroless minimal image
docker build -f dockerfiles/1-minimal/Dockerfile.distroless -t gin-webserver:minimal-distroless . --load

# Run either variant
docker run -p 8080:8080 gin-webserver:minimal-scratch
# or
docker run -p 8080:8080 gin-webserver:minimal-distroless

# Test the application
curl http://localhost:8080/health
```

When to use:

- production deployments where image size matters; smaller images deployed faster, which means upgrades and rollbacks are faster
- security-conscious environments
- resource-constrained systems (cost, time, compute, memory, bandwidth, etc...)

### Multi-stage

Optimize build process and create clean separation between build and runtime environments

> Location:`dockerfiles/2-multi-stage/Dockerfile`  

Multi-stage builds separate the build environment from the runtime environment, allowing for more efficient builds and smaller final images while maintaining build reproducibility. (Previous examples had the build and runtime as one)

Features:

- Multiple Stages
  - Dependencies:　Handles Go module downloads
  - Builder: Compiles the application with optimizations
  - Runtime: Minimal Alpine-based runtime with security hardening
  - Development: Optional stage for development workflows
- Built-in health checks
- Non-root user execution
- Optimized build flags for smaller binaries

**Build and run:**

```bash
# Build production image (default)
docker build -f dockerfiles/2-multi-stage/Dockerfile -t gin-webserver:multistage . --load

# Build development image
docker build -f dockerfiles/2-multi-stage/Dockerfile --target development -t gin-webserver:multistage-dev . --load

# Run production container
docker run -p 8080:8080 gin-webserver:multistage

# Run development container (with hot reload)
docker run -p 8080:8080 -v $(pwd):/app gin-webserver:dev

# Test the application
curl http://localhost:8080/health
```

When to use:

- CI/CD pipelines
- when you need both development and production builds
- complex build processes
- even _more_ security as non essentials tools and software is gone.

### Multi-arch

Build images that run on multiple CPU architectures (AMD64, ARM64, etc.)

> Location: `dockerfiles/3-multi-arch/Dockerfile`  

This approach creates container images that can run on different processor architectures, essential for modern cloud deployments and Apple Silicon Macs.

Features:

- Cross-compilation support for multiple architectures
- Uses `--platform` arguments for proper architecture targeting
- Optimized for both AMD64 and ARM64
- Includes security hardening
- Health checks included
- Non-root user execution

**Build and run:**
```bash
# Build for current architecture
docker build -f dockerfiles/3-multi-arch/Dockerfile -t gin-webserver:multiarch . --load

# Build for specific architecture
docker build -f dockerfiles/3-multi-arch/Dockerfile --platform linux/amd64 -t gin-webserver:multiarch-amd64 . --load
docker build -f dockerfiles/3-multi-arch/Dockerfile --platform linux/arm64 -t gin-webserver:multiarch-arm64 . --load

# Build multi-architecture image with buildx (docker specific) - optional
docker buildx create --use
docker buildx build -f dockerfiles/3-multi-arch/Dockerfile \
  --platform linux/amd64,linux/arm64 \
  -t gin-webserver:multiarch \
  --load .

# Run the container
docker run -p 8080:8080 gin-webserver:multiarch

# Test the application
curl http://localhost:8080/health
```

When to use:

- Kubernetes clusters with mixed architectures
- Apple Silicon development
- ARM-based cloud instances.

### All in one

Combines all optimization techniques into a single, production-ready Dockerfile

> Location: `dockerfiles/4-minimal-multistage-multiarch/Dockerfile`  


This is the ultimate Dockerfile that combines minimal images, multi-stage builds, and multi-architecture support into a single, highly optimized container build process.

**Advanced features:**
- **6 different build stages** for maximum flexibility
- **Multiple runtime options:** scratch, distroless, and development
- **Build optimization:** Includes UPX compression and build caching
- **Security hardening:** Non-root users, security scanning validation
- **Multi-architecture support:** Cross-compilation for all major platforms
- **Development workflow:** Includes development stage with debugging tools
- **Comprehensive labeling:** OCI-compliant metadata
- **Advanced health checks:** Built-in application health validation

**Build stages:**
1. **deps:** Dependencies and tools preparation
2. **builder:** Cross-compilation build stage
3. **security-check:** Binary validation and security scanning
4. **runtime-scratch:** Ultra-minimal scratch-based runtime
5. **runtime-distroless:** Secure distroless runtime
6. **development:** Full development environment

**Build and run:**
```bash
# Build default (distroless) image
docker build -f dockerfiles/4-minimal-multistage-multiarch/Dockerfile -t gin-webserver:aio . --load

# Build scratch variant
docker build -f dockerfiles/4-minimal-multistage-multiarch/Dockerfile --target runtime-scratch -t gin-webserver:aio . --load

# Build development image
docker build -f dockerfiles/4-minimal-multistage-multiarch/Dockerfile --target development -t gin-webserver:aio-dev . --load

# Multi-architecture build - optional
docker buildx build -f dockerfiles/4-minimal-multistage-multiarch/Dockerfile \
  --platform linux/amd64,linux/arm64 \
  -t gin-webserver:aio \
  --load .

# Run the container
docker run -p 8080:8080 gin-webserver:aio

# Test the application
curl http://localhost:8080/health
```

When to use:

- production deployments
- enterprise environments
- when you need maximum optimization and flexibility.

### Comparison Summary

| Strategy | File | Primary Focus | Image Size | Build Time | Complexity |
|----------|------|---------------|------------|------------|------------|
| **Simple** | `0-simple/` | Learning & Development | **~850MB** | Fast | Low |
| **Minimal** | `1-minimal/` | Size Optimization | **~12-16MB** | Medium | Medium |
| **Multi-Stage** | `2-multi-stage/` | Build Optimization | **~683MB** | Medium | Medium |
| **Multi-Arch** | `3-multi-arch/` | Cross-Platform | **~11.6-42.1MB** | Slow | High |
| **All-in-One** | `4-minimal-multistage-multiarch/` | Production Ready | **~17.MB** | Slow | High |

### Training Exercises

To get hands-on experience with each approach:

1. **Start with Simple:** Build and run the basic container to understand the fundamentals
2. **Compare Sizes:** Build minimal variants and compare image sizes using `docker images`
3. **Explore Multi-stage:** Build both production and development targets
4. **Test Multi-arch:** Use `docker buildx` to build for different architectures
5. **Master All-in-one:** Experiment with different targets and build options

**Useful commands for exploration:**
```bash
# Compare image sizes
docker images | grep gin-webserver

# Inspect image layers
docker history gin-webserver:simple

# Check running containers
docker ps

# View container logs
docker logs <container-id>

# Execute commands in running container
docker exec -it <container-id> /bin/sh
```

### Useful Concepts

- build cashing:　cache layers to speed up rebuilding

## Kubernetes

Deploy to k8s

### raw manifests 

> not recommended

### Helm



### Skaffold
