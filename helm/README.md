# Gin Webserver Helm Chart

A Helm chart for deploying the Gin webserver application on Kubernetes with comprehensive configuration options.

## Quick Start

```bash
# Install development environment
./skaffold.sh helm-install dev

# Install production environment
./skaffold.sh helm-install prod

# Or use Skaffold for continuous development
./skaffold.sh dev
```

## Chart Structure

```
helm/gin-webserver/
├── Chart.yaml                 # Chart metadata
├── values.yaml                # Default configuration values
├── values-dev.yaml            # Development environment overrides
├── values-prod.yaml           # Production environment overrides
└── templates/
    ├── _helpers.tpl           # Template helpers
    ├── configmap.yaml         # ConfigMap for application config
    ├── deployment.yaml        # Deployment manifest
    ├── hpa.yaml              # Horizontal Pod Autoscaler
    ├── ingress.yaml          # Ingress configuration
    ├── networkpolicy.yaml    # Network policy for security
    ├── NOTES.txt             # Post-install instructions
    ├── poddisruptionbudget.yaml # Pod disruption budget
    ├── service.yaml          # Service manifest
    ├── serviceaccount.yaml   # Service account
    └── servicemonitor.yaml   # Prometheus ServiceMonitor
```

## Configuration

### Basic Configuration

The chart provides sensible defaults but can be customized through values files:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `1` |
| `image.repository` | Image repository | `gin-webserver` |
| `image.tag` | Image tag | `latest` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `80` |
| `ingress.enabled` | Enable ingress | `false` |

### Environment-Specific Values

#### Development (`values-dev.yaml`)
- Single replica for faster development
- Debug mode enabled (`GIN_MODE=debug`)
- Higher resource limits for development tools
- Relaxed security policies for debugging
- Local ingress configuration

#### Production (`values-prod.yaml`)
- Multiple replicas (3) with anti-affinity
- Release mode (`GIN_MODE=release`)
- Horizontal Pod Autoscaler enabled
- Pod Disruption Budget for high availability
- Strict security policies
- TLS-enabled ingress
- Monitoring integration

### Security Configuration

The chart includes comprehensive security settings:

```yaml
# Pod Security Context
podSecurityContext:
  runAsNonRoot: true
  runAsUser: 65534
  fsGroup: 65534
  seccompProfile:
    type: RuntimeDefault

# Container Security Context
securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  runAsUser: 65534
  capabilities:
    drop:
    - ALL
```

### Resource Management

Default resource requests and limits:

```yaml
resources:
  limits:
    cpu: 200m
    memory: 128Mi
  requests:
    cpu: 50m
    memory: 32Mi
```

### Monitoring Integration

The chart supports Prometheus monitoring:

```yaml
serviceMonitor:
  enabled: true
  namespace: monitoring
  interval: 30s
  path: /metrics
```

## Installation

### Using Helm Directly

```bash
# Install with default values
helm install gin-webserver helm/gin-webserver

# Install development environment
helm install gin-webserver-dev helm/gin-webserver \
  --namespace gin-webserver-dev \
  --create-namespace \
  --values helm/gin-webserver/values-dev.yaml

# Install production environment
helm install gin-webserver-prod helm/gin-webserver \
  --namespace gin-webserver-prod \
  --create-namespace \
  --values helm/gin-webserver/values-prod.yaml
```

### Using Skaffold (Recommended)

Skaffold provides a better development experience with automatic builds and deployments:

```bash
# Development with file sync and port forwarding
./skaffold.sh dev

# Production deployment
./skaffold.sh run prod

# Multi-architecture deployment
./skaffold.sh run multiarch
```

## Customization

### Adding Custom Configuration

Create custom values in a ConfigMap:

```yaml
configMaps:
  app.yaml: |
    database:
      host: postgres.example.com
      port: 5432
    redis:
      host: redis.example.com
      port: 6379
```

### Environment Variables

Add custom environment variables:

```yaml
extraEnvVars:
  - name: DATABASE_URL
    value: "postgres://user:pass@host:5432/db"
  - name: REDIS_URL
    value: "redis://redis:6379/0"

# From ConfigMaps or Secrets
extraEnvVarsFromConfigMaps:
  - configMapRef:
      name: app-config

extraEnvVarsFromSecrets:
  - secretRef:
      name: app-secrets
```

### Volume Mounts

Add persistent storage or configuration files:

```yaml
extraVolumeMounts:
  - name: config-volume
    mountPath: /etc/config
  - name: data-volume
    mountPath: /data

extraVolumes:
  - name: config-volume
    configMap:
      name: app-config
  - name: data-volume
    persistentVolumeClaim:
      claimName: app-data-pvc
```

### Init Containers

Add initialization logic:

```yaml
initContainers:
  - name: migration
    image: migrate/migrate:latest
    command: ['migrate', '-path', '/migrations', '-database', '$(DATABASE_URL)', 'up']
    env:
      - name: DATABASE_URL
        valueFrom:
          secretKeyRef:
            name: db-secret
            key: url
```

## Advanced Features

### Horizontal Pod Autoscaler

Enable automatic scaling based on CPU/memory usage:

```yaml
autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80
```

### Pod Disruption Budget

Ensure high availability during node maintenance:

```yaml
podDisruptionBudget:
  enabled: true
  minAvailable: 2
```

### Network Policies

Restrict network access for security:

```yaml
networkPolicy:
  enabled: true
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: ingress-nginx
      ports:
        - protocol: TCP
          port: 8080
```

### Ingress Configuration

Configure external access with TLS:

```yaml
ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
  hosts:
    - host: gin-webserver.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: gin-webserver-tls
      hosts:
        - gin-webserver.example.com
```

## Validation and Testing

### Chart Validation

```bash
# Lint the chart
./skaffold.sh validate

# Dry run installation
helm install gin-webserver helm/gin-webserver --dry-run --debug

# Template rendering
./skaffold.sh templates dev
./skaffold.sh templates prod
```

### Testing Deployment

```bash
# Test health endpoints
./skaffold.sh test gin-webserver-dev gin-webserver-dev

# Manual testing
kubectl run test-pod --image=curlimages/curl --rm -i --restart=Never \
  -- curl -f http://gin-webserver-dev.gin-webserver-dev/health
```

## Troubleshooting

### Common Issues

1. **Image Pull Errors**
   ```bash
   # Check image availability
   kubectl describe pod <pod-name> -n <namespace>
   
   # Verify image repository and tag
   helm get values gin-webserver-dev
   ```

2. **Service Discovery Issues**
   ```bash
   # Check service endpoints
   kubectl get endpoints -n <namespace>
   
   # Test service connectivity
   kubectl run debug --image=nicolaka/netshoot --rm -i --tty
   ```

3. **Ingress Not Working**
   ```bash
   # Check ingress controller
   kubectl get pods -n ingress-nginx
   
   # Verify ingress configuration
   kubectl describe ingress gin-webserver -n <namespace>
   ```

4. **Resource Constraints**
   ```bash
   # Check resource usage
   kubectl top pods -n <namespace>
   
   # Check events for scheduling issues
   kubectl get events -n <namespace> --sort-by='.lastTimestamp'
   ```

### Debug Commands

```bash
# View rendered templates
helm template gin-webserver-dev helm/gin-webserver \
  --values helm/gin-webserver/values-dev.yaml

# Check deployment status
kubectl rollout status deployment/gin-webserver-dev -n gin-webserver-dev

# View pod logs
kubectl logs -f deployment/gin-webserver-dev -n gin-webserver-dev

# Execute commands in pod
kubectl exec -it deployment/gin-webserver-dev -n gin-webserver-dev -- /bin/sh
```

## Integration Examples

### CI/CD Pipeline

```yaml
# .github/workflows/deploy.yml
name: Deploy to Kubernetes
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Skaffold
        run: |
          curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64
          sudo install skaffold /usr/local/bin/
      
      - name: Deploy to staging
        run: ./skaffold.sh run dev
        
      - name: Deploy to production
        if: github.ref == 'refs/heads/main'
        run: ./skaffold.sh run prod
```

### ArgoCD Application

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: gin-webserver
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/gin-webserver
    targetRevision: HEAD
    path: helm/gin-webserver
    helm:
      valueFiles:
        - values.yaml
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

### Monitoring Stack

```yaml
# values-prod.yaml addition for monitoring
serviceMonitor:
  enabled: true
  namespace: monitoring
  labels:
    release: prometheus

# Grafana dashboard configuration
grafana:
  dashboards:
    default:
      gin-webserver:
        gnetId: 6417
        revision: 1
        datasource: Prometheus
```

## Migration Guide

### From Raw Kubernetes Manifests

If migrating from the previous k8s/ directory structure:

1. **Values Mapping**: Map your existing configuration to values.yaml
2. **Namespace Changes**: Update any hardcoded namespaces
3. **Label Updates**: Ensure label selectors match Helm conventions
4. **Secret Management**: Migrate secrets to Helm or external secret managers

### From Docker Compose

```bash
# Convert docker-compose.yml to Helm values
kompose convert --chart --out helm/gin-webserver-compose/
```

## Best Practices

### Security
- Always run as non-root user
- Use read-only root filesystem
- Drop all capabilities
- Enable Pod Security Standards
- Use network policies in production

### Performance
- Set appropriate resource requests and limits
- Use horizontal pod autoscaling
- Configure pod disruption budgets
- Implement proper health checks

### Monitoring
- Enable ServiceMonitor for Prometheus
- Configure proper logging
- Set up alerting rules
- Use distributed tracing

### Maintenance
- Keep charts updated
- Use semantic versioning
- Document all customizations
- Test deployments in staging first

## Support

For issues and questions:
- Check the troubleshooting section
- Review Helm chart documentation
- Check Kubernetes events and logs
- Use `./skaffold.sh check` to verify prerequisites

## Contributing

1. Validate changes with `./skaffold.sh validate`
2. Test in development environment
3. Update documentation
4. Submit pull request with detailed description
