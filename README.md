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

This section demonstrates different approaches to deploying the gin-webserver to Kubernetes, from basic raw manifests to advanced GitOps workflows with skaffold and argocd

### Prerequisites

- Kubernetes cluster (local: minikube, kind, k3s, or cloud: EKS, GKE, AKS)
- `kubectl` configured to connect to your cluster
- Helm 3.x installed
- Docker registry access (Docker Hub, ECR, GCR, etc.)

### Raw Kubernetes Manifests

> **Note:** While functional for learning, raw manifests are not recommended for production. Use Helm or Kustomize instead.

Basic deployment using vanilla Kubernetes YAML files.

**Location:** `k8s/raw-manifests/`

#### Files included:

- `namespace.yaml` - Dedicated namespace for the application
- `deployment.yaml` - Application deployment with resource limits
- `service.yaml` - ClusterIP service for internal communication
- `ingress.yaml` - Ingress for external access
- `configmap.yaml` - Configuration data
- `secret.yaml` - Sensitive configuration (base64 encoded)
- `hpa.yaml` - Horizontal Pod Autoscaler
- `networkpolicy.yaml` - Network security policies

#### Deploy raw manifests:

```bash
# Apply all manifests
kubectl apply -f ./k8s-manifests/

# Verify deployment
kubectl get pods -n gin-webserver
kubectl get svc -n gin-webserver

# Check application logs
kubectl logs -l app=gin-webserver -n gin-webserver

# Port forward to test locally
kubectl port-forward svc/gin-webserver 8080:80 -n gin-webserver

# Test the application
curl http://localhost:8080/health

# Clean up
kubectl delete -f k8s/raw-manifests/
```

#### When to use raw manifests

- Learning Kubernetes fundamentals
- Simple, one-off deployments or prototypes
- CI/CD pipelines with template substitution
- When you need maximum control over every detail

### Helm Charts

Helm provides templating, versioning, and lifecycle management for Kubernetes applications.

**Location:** `helm/gin-webserver/`

#### Chart Structure:
```
helm/gin-webserver/
├── Chart.yaml           # Chart metadata
├── values.yaml          # Default configuration values
├── values-dev.yaml      # Development environment overrides
├── values-staging.yaml  # Staging environment overrides  
├── values-prod.yaml     # Production environment overrides
├── templates/
│   ├── deployment.yaml  # Deployment template
│   ├── service.yaml     # Service template
│   ├── ingress.yaml     # Ingress template
│   ├── configmap.yaml   # ConfigMap template
│   ├── secret.yaml      # Secret template
│   ├── hpa.yaml         # HPA template
│   ├── pdb.yaml         # PodDisruptionBudget template
│   ├── networkpolicy.yaml # NetworkPolicy template
│   ├── serviceaccount.yaml # ServiceAccount template
│   ├── rbac.yaml        # RBAC templates
│   └── tests/
│       └── test-connection.yaml # Helm tests
├── charts/              # Dependency charts (if any)
└── crds/               # Custom Resource Definitions
```

#### Key Helm Features Demonstrated:

**Templating and Values:**
- Environment-specific value files
- Conditional resource creation
- Dynamic configuration based on environment
- Resource scaling based on environment type

**Security Features:**
- RBAC configuration
- Pod Security Contexts
- Network Policies
- Secret management

**Reliability Features:**
- Health checks and probes
- Resource limits and requests
- Pod Disruption Budgets
- Horizontal Pod Autoscaling

#### Deploy with Helm:

```bash
# Add dependencies (if any)
helm dependency update helm/gin-webserver

# Install to development environment
helm install gin-webserver-dev helm/gin-webserver \
  -f helm/gin-webserver/values-dev.yaml \
  --namespace gin-webserver-dev \
  --create-namespace

# Install to production environment
helm install gin-webserver-prod helm/gin-webserver \
  -f helm/gin-webserver/values-prod.yaml \
  --namespace gin-webserver-prod \
  --create-namespace

# Override specific values
helm install gin-webserver helm/gin-webserver \
  --set image.tag=v1.2.0 \
  --set replicaCount=3 \
  --set ingress.enabled=true

# Upgrade deployment
helm upgrade gin-webserver-prod helm/gin-webserver \
  -f helm/gin-webserver/values-prod.yaml

# Check deployment status
helm status gin-webserver-prod
helm list -A

# Run Helm tests
helm test gin-webserver-prod

# Rollback if needed
helm rollback gin-webserver-prod 1

# Uninstall
helm uninstall gin-webserver-prod --namespace gin-webserver-prod
```

#### Helm Training Exercises:

1. **Basic Deployment:**
   ```bash
   # Deploy with default values
   helm install my-gin helm/gin-webserver
   
   # Check what was created
   kubectl get all -l app.kubernetes.io/instance=my-gin
   ```

2. **Environment Customization:**
  The following generates k8s manifests
  
   ```bash
   # Compare different environment configurations
   helm template gin-webserver helm/gin-webserver -f helm/gin-webserver/values-dev.yaml
   helm template gin-webserver helm/gin-webserver -f helm/gin-webserver/values-prod.yaml
   ```

3. **Value Overrides:**
   ```bash
   # Practice overriding values
   helm install test-gin helm/gin-webserver \
     --set image.tag=latest \
     --set service.type=NodePort \
     --set ingress.enabled=false \
     --dry-run --debug
   ```

4. **Upgrade and Rollback:**
   ```bash
   # Simulate production upgrade
   helm upgrade test-gin helm/gin-webserver --set image.tag=v2.0.0
   helm history test-gin
   helm rollback test-gin 1
   ```

#### Advanced Helm Features:

**Chart Dependencies:**
```yaml
# Chart.yaml
dependencies:
  - name: postgresql
    version: "12.1.9"
    repository: "https://charts.bitnami.com/bitnami"
    condition: postgresql.enabled
  - name: redis
    version: "17.4.3"
    repository: "https://charts.bitnami.com/bitnami"
    condition: redis.enabled
```

**Helm Hooks for Advanced Lifecycle Management:**
- Pre-install hooks for database migrations
- Post-install hooks for configuration
- Pre-upgrade hooks for backup
- Test hooks for validation

#### When to use Helm:
- Multi-environment deployments
- Complex applications with many components
- When you need versioning and rollback capabilities
- Team collaboration on Kubernetes deployments
- Production workloads

### Kustomize (Alternative to Helm)

**Location:** `k8s/kustomize/`

Kustomize provides declarative configuration management without templating:

```bash
# Base configuration
kustomize build k8s/kustomize/base

# Environment-specific overlays
kustomize build k8s/kustomize/overlays/development
kustomize build k8s/kustomize/overlays/production

# Apply with kubectl
kubectl apply -k k8s/kustomize/overlays/production
```

### Monitoring and Observability

#### Prometheus Metrics:
The application exposes metrics at `/metrics` endpoint for Prometheus scraping.

```bash
# Add Prometheus annotations to deployment
kubectl annotate deployment gin-webserver prometheus.io/scrape=true
kubectl annotate deployment gin-webserver prometheus.io/port=8080
kubectl annotate deployment gin-webserver prometheus.io/path=/metrics
```

#### Logging:
Structured JSON logging is configured for easy parsing by log aggregators:

```bash
# View application logs
kubectl logs -l app=gin-webserver --tail=100 -f

# Export logs to file
kubectl logs -l app=gin-webserver --since=1h > app-logs.json
```

#### Health Checks:
Multiple health check endpoints for different purposes:
- `/health` - Basic health endpoint
- `/readiness` - Readiness probe endpoint
- `/liveness` - Liveness probe endpoint

### Security Best Practices

#### Pod Security:
```yaml
# Implemented in Helm templates
securityContext:
  runAsNonRoot: true
  runAsUser: 65534
  fsGroup: 65534
  capabilities:
    drop:
      - ALL
  readOnlyRootFilesystem: true
```

#### Network Security:
```bash
# Network policies are included in both raw manifests and Helm charts
kubectl get networkpolicy -n gin-webserver
```

#### Secret Management:
```bash
# Use external secret management in production
# Examples for different secret managers:

# AWS Secrets Manager
kubectl apply -f k8s/external-secrets/aws-secrets.yaml

# HashiCorp Vault
kubectl apply -f k8s/external-secrets/vault-secrets.yaml

# Azure Key Vault
kubectl apply -f k8s/external-secrets/azure-keyvault.yaml
```

### Troubleshooting Commands

```bash
# Check pod status and events
kubectl get pods -n gin-webserver -o wide
kubectl describe pod <pod-name> -n gin-webserver

# Check service and endpoints
kubectl get svc,endpoints -n gin-webserver

# Check ingress configuration
kubectl get ingress -n gin-webserver -o yaml

# View recent events
kubectl get events -n gin-webserver --sort-by='.lastTimestamp'

# Debug network connectivity
kubectl run debug --image=nicolaka/netshoot -it --rm

# Check resource usage
kubectl top pods -n gin-webserver
kubectl top nodes
```

### Skaffold - Development Workflow

**Location:** `skaffold.yaml`

Skaffold automates the development workflow for Kubernetes applications.

#### Features:
- Automatic image building and deployment
- File watching for hot reloading
- Port forwarding
- Log streaming
- Multiple environment profiles

#### Skaffold Configuration:
```yaml
# skaffold.yaml example structure
apiVersion: skaffold/v4beta1
kind: Config
metadata:
  name: gin-webserver
  
build:
  artifacts:
  - image: gin-webserver
    docker:
      dockerfile: dockerfiles/2-multi-stage/Dockerfile
  local:
    push: false
    
deploy:
  helm:
    releases:
    - name: gin-webserver-dev
      chartPath: helm/gin-webserver
      valuesFiles:
      - helm/gin-webserver/values-dev.yaml
      namespace: gin-webserver-dev
      createNamespace: true
      
portForward:
- resourceType: service
  resourceName: gin-webserver
  namespace: gin-webserver-dev
  port: 8080
  localPort: 8080

profiles:
- name: production
  deploy:
    helm:
      releases:
      - name: gin-webserver-prod
        chartPath: helm/gin-webserver
        valuesFiles:
        - helm/gin-webserver/values-prod.yaml
        namespace: gin-webserver-prod
```

#### Using Skaffold:

```bash
# Development mode with file watching
skaffold dev

# Build and deploy once
skaffold run

# Deploy to production profile
skaffold run -p production

# Debug mode
skaffold debug

# Clean up
skaffold delete
```

#### Skaffold Training Exercises:

1. **Development Workflow:**
   ```bash
   # Start development mode
   skaffold dev
   
   # In another terminal, make changes to main.go
   # Watch Skaffold automatically rebuild and redeploy
   ```

2. **Profile Switching:**
   ```bash
   # Switch between development and production profiles
   skaffold run -p development
   skaffold run -p production
   ```

3. **Debugging:**
   ```bash
   # Enable debug mode for troubleshooting
   skaffold debug --port-forward
   ```

### GitOps with ArgoCD (Advanced)

**Location:** `gitops/argocd/`

For production environments, consider implementing GitOps workflows:

```yaml
# Application definition for ArgoCD
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: gin-webserver-prod
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/gin-webserver
    targetRevision: main
    path: helm/gin-webserver
    helm:
      valueFiles:
      - values-prod.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: gin-webserver-prod
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

### Kubernetes Training Progression

**Beginner Level:**
1. Deploy using raw manifests
2. Understand pods, services, and deployments
3. Practice kubectl commands
4. Learn about namespaces and labels

**Intermediate Level:**
1. Create and customize Helm charts
2. Use different value files for environments
3. Implement health checks and resource limits
4. Practice upgrades and rollbacks

**Advanced Level:**
1. Implement comprehensive monitoring
2. Set up GitOps workflows
3. Configure security policies
4. Optimize for production workloads
5. Implement CI/CD pipelines

**Production Checklist:**
- [ ] Resource limits and requests configured
- [ ] Health checks implemented (liveness, readiness, startup)
- [ ] Monitoring and alerting configured
- [ ] Security contexts and policies applied
- [ ] Network policies implemented
- [ ] Backup and disaster recovery plan
- [ ] GitOps workflow established
- [ ] Documentation and runbooks created
