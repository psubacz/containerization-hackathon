#!/bin/bash

# Skaffold + Helm helper scripts for gin-webserver

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if skaffold is installed
    if ! command -v skaffold &> /dev/null; then
        log_error "Skaffold is not installed. Please install it from https://skaffold.dev/docs/install/"
        exit 1
    fi
    
    # Check if kubectl is installed and configured
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed. Please install it first."
        exit 1
    fi
    
    # Check if helm is installed
    if ! command -v helm &> /dev/null; then
        log_error "Helm is not installed. Please install it from https://helm.sh/docs/intro/install/"
        exit 1
    fi
    
    # Check if cluster is accessible
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster. Please check your kubectl configuration."
        exit 1
    fi
    
    # Check if buildah is available (optional)
    if command -v buildah &> /dev/null; then
        log_success "Buildah found - will use for builds"
    else
        log_warning "Buildah not found - will use Docker for builds"
    fi
    
    # Validate Helm chart
    log_info "Validating Helm chart..."
    if ! helm lint helm/gin-webserver/ &> /dev/null; then
        log_error "Helm chart validation failed"
        exit 1
    fi
    
    log_success "Prerequisites check passed!"
}

# Development workflow
dev() {
    log_info "Starting development workflow..."
    check_prerequisites
    
    log_info "Running Skaffold in development mode with Helm and file sync..."
    skaffold dev --profile=dev --port-forward=true --cleanup=true
}

# Local development (uses default namespace)
local() {
    log_info "Starting local development workflow..."
    check_prerequisites
    
    log_info "Running Skaffold in local mode (default namespace)..."
    skaffold dev --profile=local --port-forward=true --cleanup=true
}

# Run specific profile
run_profile() {
    local profile=$1
    if [ -z "$profile" ]; then
        log_error "Profile name required. Available profiles: dev, prod, multiarch, local"
        exit 1
    fi
    
    log_info "Running Skaffold with profile: $profile"
    check_prerequisites
    
    skaffold run --profile="$profile"
}

# Build and deploy
build_deploy() {
    local profile=${1:-"default"}
    log_info "Building and deploying with profile: $profile"
    check_prerequisites
    
    if [ "$profile" = "default" ]; then
        skaffold run
    else
        skaffold run --profile="$profile"
    fi
    
    log_success "Deployment completed!"
}

# Debug mode
debug() {
    log_info "Starting debug mode..."
    check_prerequisites
    
    skaffold debug --profile=dev --port-forward=true
}

# Delete deployment
delete() {
    local profile=${1:-"default"}
    log_info "Deleting deployment with profile: $profile"
    
    if [ "$profile" = "default" ]; then
        skaffold delete
    else
        skaffold delete --profile="$profile"
    fi
    
    log_success "Deployment deleted!"
}

# Clean up
cleanup() {
    log_info "Cleaning up all resources..."
    
    # Delete from all profiles
    skaffold delete --profile=dev || true
    skaffold delete --profile=prod || true
    skaffold delete --profile=multiarch || true
    skaffold delete --profile=local || true
    skaffold delete || true
    
    log_success "Cleanup completed!"
}

# Show status
status() {
    log_info "Checking deployment status..."
    
    echo -e "\n${BLUE}=== Default Namespace ===${NC}"
    kubectl get pods,svc,ingress -n gin-webserver 2>/dev/null || echo "No resources in gin-webserver namespace"
    
    echo -e "\n${BLUE}=== Development Namespace ===${NC}"
    kubectl get pods,svc,ingress -n gin-webserver-dev 2>/dev/null || echo "No resources in gin-webserver-dev namespace"
    
    echo -e "\n${BLUE}=== Production Namespace ===${NC}"
    kubectl get pods,svc,ingress,hpa,pdb -n gin-webserver-prod 2>/dev/null || echo "No resources in gin-webserver-prod namespace"
    
    echo -e "\n${BLUE}=== Local (default namespace) ===${NC}"
    kubectl get pods,svc -l app.kubernetes.io/name=gin-webserver 2>/dev/null || echo "No gin-webserver resources in default namespace"
}

# Show logs
logs() {
    local namespace=${1:-"gin-webserver-dev"}
    local release=${2:-"gin-webserver-dev"}
    log_info "Showing logs from namespace: $namespace, release: $release"
    
    kubectl logs -f deployment/"$release" -n "$namespace"
}

# Port forward
port_forward() {
    local namespace=${1:-"gin-webserver-dev"}
    local release=${2:-"gin-webserver-dev"}
    local port=${3:-"8080"}
    
    log_info "Port forwarding from namespace $namespace, service $release to local port $port"
    kubectl port-forward -n "$namespace" service/"$release" "$port":80
}

# Helm operations
helm_install() {
    local environment=${1:-"dev"}
    local release_name="gin-webserver-$environment"
    local namespace="gin-webserver-$environment"
    
    log_info "Installing Helm release: $release_name in namespace: $namespace"
    check_prerequisites
    
    # Create namespace if it doesn't exist
    kubectl create namespace "$namespace" --dry-run=client -o yaml | kubectl apply -f -
    
    if [ "$environment" = "dev" ]; then
        helm upgrade --install "$release_name" helm/gin-webserver \
            --namespace "$namespace" \
            --values helm/gin-webserver/values.yaml \
            --values helm/gin-webserver/values-dev.yaml \
            --set image.tag=manual \
            --wait
    elif [ "$environment" = "prod" ]; then
        helm upgrade --install "$release_name" helm/gin-webserver \
            --namespace "$namespace" \
            --values helm/gin-webserver/values.yaml \
            --values helm/gin-webserver/values-prod.yaml \
            --set image.tag=manual \
            --wait
    else
        helm upgrade --install "$release_name" helm/gin-webserver \
            --namespace "$namespace" \
            --values helm/gin-webserver/values.yaml \
            --set image.tag=manual \
            --wait
    fi
    
    log_success "Helm release $release_name installed successfully!"
}

# Helm uninstall
helm_uninstall() {
    local environment=${1:-"dev"}
    local release_name="gin-webserver-$environment"
    local namespace="gin-webserver-$environment"
    
    log_info "Uninstalling Helm release: $release_name from namespace: $namespace"
    
    helm uninstall "$release_name" --namespace "$namespace" || true
    kubectl delete namespace "$namespace" --ignore-not-found=true
    
    log_success "Helm release $release_name uninstalled!"
}

# Validate Helm chart
validate_chart() {
    log_info "Validating Helm chart..."
    
    # Lint the chart
    helm lint helm/gin-webserver/
    
    # Dry run with different values files
    echo -e "\n${BLUE}=== Validating default values ===${NC}"
    helm template gin-webserver helm/gin-webserver/ --debug --dry-run > /dev/null
    
    echo -e "\n${BLUE}=== Validating dev values ===${NC}"
    helm template gin-webserver-dev helm/gin-webserver/ \
        --values helm/gin-webserver/values-dev.yaml \
        --debug --dry-run > /dev/null
    
    echo -e "\n${BLUE}=== Validating prod values ===${NC}"
    helm template gin-webserver-prod helm/gin-webserver/ \
        --values helm/gin-webserver/values-prod.yaml \
        --debug --dry-run > /dev/null
    
    log_success "Helm chart validation passed!"
}

# Show rendered templates
show_templates() {
    local environment=${1:-"default"}
    
    if [ "$environment" = "dev" ]; then
        helm template gin-webserver-dev helm/gin-webserver/ \
            --values helm/gin-webserver/values.yaml \
            --values helm/gin-webserver/values-dev.yaml
    elif [ "$environment" = "prod" ]; then
        helm template gin-webserver-prod helm/gin-webserver/ \
            --values helm/gin-webserver/values.yaml \
            --values helm/gin-webserver/values-prod.yaml
    else
        helm template gin-webserver helm/gin-webserver/ \
            --values helm/gin-webserver/values.yaml
    fi
}

# Test deployment
test_deployment() {
    local namespace=${1:-"gin-webserver-dev"}
    local release=${2:-"gin-webserver-dev"}
    
    log_info "Testing deployment in namespace: $namespace"
    
    # Wait for deployment to be ready
    kubectl wait --for=condition=available --timeout=300s deployment/"$release" -n "$namespace"
    
    # Test health endpoint
    log_info "Testing health endpoint..."
    kubectl run test-pod --image=curlimages/curl:latest --rm -i --restart=Never -n "$namespace" \
        -- curl -f "http://$release/health"
    
    log_success "Deployment test passed!"
}

# Help
show_help() {
    echo "Skaffold + Helm helper script for gin-webserver"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Skaffold Commands:"
    echo "  dev                     Start development workflow with Helm deployment"
    echo "  local                   Start local development (default namespace)"
    echo "  run <profile>           Run with specific profile (dev, prod, multiarch, local)"
    echo "  deploy [profile]        Build and deploy (default profile if not specified)"
    echo "  debug                   Start in debug mode"
    echo "  delete [profile]        Delete deployment"
    echo "  cleanup                 Clean up all resources from all profiles"
    echo ""
    echo "Helm Commands:"
    echo "  helm-install <env>      Install Helm chart (dev, prod, or default)"
    echo "  helm-uninstall <env>    Uninstall Helm chart"
    echo "  validate                Validate Helm chart"
    echo "  templates [env]         Show rendered templates"
    echo ""
    echo "Management Commands:"
    echo "  status                  Show deployment status across all namespaces"
    echo "  logs [namespace] [release] [port]  Show logs"
    echo "  port-forward [ns] [release] [port] Port forward service"
    echo "  test [namespace] [release]         Test deployment"
    echo "  check                   Check prerequisites"
    echo "  help                    Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 dev                              # Start development workflow"
    echo "  $0 run prod                         # Deploy to production"
    echo "  $0 deploy multiarch                 # Deploy multi-architecture build"
    echo "  $0 helm-install dev                 # Install dev environment with Helm"
    echo "  $0 logs gin-webserver-prod gin-webserver-prod  # Show production logs"
    echo "  $0 validate                         # Validate Helm chart"
    echo "  $0 templates prod                   # Show production templates"
}

# Main script logic
case "${1:-help}" in
    "dev")
        dev
        ;;
    "local")
        local
        ;;
    "run")
        run_profile "$2"
        ;;
    "deploy")
        build_deploy "$2"
        ;;
    "debug")
        debug
        ;;
    "delete")
        delete "$2"
        ;;
    "cleanup")
        cleanup
        ;;
    "helm-install")
        helm_install "$2"
        ;;
    "helm-uninstall")
        helm_uninstall "$2"
        ;;
    "validate")
        validate_chart
        ;;
    "templates")
        show_templates "$2"
        ;;
    "status")
        status
        ;;
    "logs")
        logs "$2" "$3"
        ;;
    "port-forward")
        port_forward "$2" "$3" "$4"
        ;;
    "test")
        test_deployment "$2" "$3"
        ;;
    "check")
        check_prerequisites
        ;;
    "help"|*)
        show_help
        ;;
esac
