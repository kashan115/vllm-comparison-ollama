#!/bin/bash
# deploy-vllm-k8s-cpu.sh
# Deploy vLLM on Kubernetes with CPU-only mode (for testing without GPU)

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_info() {
    echo -e "${YELLOW}➜${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

echo "=================================================="
echo "vLLM CPU-Only Deployment (for testing)"
echo "=================================================="
print_warning "Note: CPU inference is MUCH slower than GPU"
print_warning "This is for testing the Kubernetes setup only"
echo ""

# Check prerequisites
print_info "Checking prerequisites..."

if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed"
    exit 1
fi
print_success "kubectl is installed"

if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster"
    exit 1
fi
print_success "Kubernetes cluster is accessible"

# Clean up existing deployment if any
print_info "Cleaning up any existing deployment..."
kubectl delete deployment vllm-deployment -n vllm 2>/dev/null || true
kubectl delete service vllm-service -n vllm 2>/dev/null || true
sleep 2

# Create namespace
print_info "Creating namespace..."
kubectl apply -f kubernetes/namespace.yaml
print_success "Namespace created"

# Deploy vLLM (CPU version)
print_info "Deploying vLLM with CPU mode..."
kubectl apply -f kubernetes/vllm-deployment-cpu.yaml
print_success "Deployment created"

# Create service
print_info "Creating service..."
kubectl apply -f kubernetes/vllm-service.yaml
print_success "Service created"

# Show immediate status
echo ""
print_info "Checking pod status..."
kubectl get pods -n vllm

# Wait for deployment with longer timeout
echo ""
print_info "Waiting for deployment to be ready (this may take 5-10 minutes)..."
print_info "The model will be downloaded on first run..."
print_info "You can watch progress with: kubectl logs -f deployment/vllm-deployment -n vllm"
echo ""

if kubectl wait --for=condition=available --timeout=600s deployment/vllm-deployment -n vllm 2>&1; then
    print_success "Deployment is ready"
else
    print_error "Deployment did not become ready in time"
    echo ""
    echo "Check the status with:"
    echo "  kubectl get pods -n vllm"
    echo "  kubectl describe pod -n vllm"
    echo "  kubectl logs -f deployment/vllm-deployment -n vllm"
    echo ""
    echo "The pod may still be starting. Common reasons for delays:"
    echo "  - Model is being downloaded (can take several minutes)"
    echo "  - Container image is being pulled"
    echo "  - Insufficient resources"
    exit 1
fi

# Show status
echo ""
echo "=================================================="
echo "vLLM Deployment Status"
echo "=================================================="
kubectl get all -n vllm

echo ""
echo "=================================================="
echo "Next Steps"
echo "=================================================="
echo "1. In a NEW terminal, start port forwarding:"
echo "   kubectl port-forward service/vllm-service 8000:8000 -n vllm"
echo ""
echo "2. In another terminal, test the API:"
echo "   curl http://localhost:8000/v1/models"
echo ""
echo "3. View logs:"
echo "   kubectl logs -f deployment/vllm-deployment -n vllm"
echo ""
echo "4. Run benchmark (will be slow on CPU!):"
echo "   python3 kubernetes_vllm_concurrent_benchmark.py"
echo ""
echo "5. When done, clean up:"
echo "   kubectl delete namespace vllm"
echo "=================================================="
