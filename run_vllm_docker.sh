#!/bin/bash

# vLLM Docker Runner Script
# This script simplifies running vLLM in Docker with common configurations

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Default values
MODEL="TinyLlama/TinyLlama-1.1B-Chat-v1.0"
PORT=8000
CONTAINER_NAME="vllm-server"
GPU_MEMORY=0.9
MAX_MODEL_LEN=4096
TENSOR_PARALLEL_SIZE=1

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    print_info "Docker is installed ✓"
}

# Function to check if NVIDIA runtime is available
check_nvidia_runtime() {
    if docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu20.04 nvidia-smi &> /dev/null; then
        print_info "NVIDIA GPU runtime is available ✓"
        return 0
    else
        print_warn "NVIDIA GPU runtime not available. Will use CPU mode."
        return 1
    fi
}

# Function to stop and remove existing container
cleanup_container() {
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        print_info "Stopping and removing existing container: ${CONTAINER_NAME}"
        docker stop ${CONTAINER_NAME} 2>/dev/null || true
        docker rm ${CONTAINER_NAME} 2>/dev/null || true
    fi
}

# Function to pull Docker image
pull_image() {
    print_info "Pulling vLLM Docker image..."
    docker pull vllm/vllm-openai:latest
}

# Function to run vLLM with GPU
run_with_gpu() {
    print_info "Starting vLLM server with GPU support..."
    print_info "Model: ${MODEL}"
    print_info "Port: ${PORT}"
    print_info "GPU Memory Utilization: ${GPU_MEMORY}"
    
    docker run -d \
        --name ${CONTAINER_NAME} \
        --runtime nvidia \
        --gpus all \
        -v ~/.cache/huggingface:/root/.cache/huggingface \
        -p ${PORT}:8000 \
        --ipc=host \
        vllm/vllm-openai:latest \
        --model ${MODEL} \
        --host 0.0.0.0 \
        --port 8000 \
        --tensor-parallel-size ${TENSOR_PARALLEL_SIZE} \
        --max-model-len ${MAX_MODEL_LEN} \
        --gpu-memory-utilization ${GPU_MEMORY}
}

# Function to run vLLM with CPU
run_with_cpu() {
    print_warn "Starting vLLM server with CPU (slower performance)..."
    print_info "Model: ${MODEL}"
    print_info "Port: ${PORT}"
    
    docker run -d \
        --name ${CONTAINER_NAME} \
        -v ~/.cache/huggingface:/root/.cache/huggingface \
        -p ${PORT}:8000 \
        vllm/vllm-openai:latest \
        --model ${MODEL} \
        --host 0.0.0.0 \
        --port 8000 \
        --device cpu
}

# Function to wait for server to be ready
wait_for_server() {
    print_info "Waiting for vLLM server to start..."
    local max_attempts=60
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -s http://localhost:${PORT}/health > /dev/null 2>&1; then
            print_info "Server is ready! ✓"
            return 0
        fi
        sleep 2
        attempt=$((attempt + 1))
        echo -n "."
    done
    
    echo ""
    print_error "Server failed to start within timeout."
    print_info "Check logs with: docker logs ${CONTAINER_NAME}"
    return 1
}

# Function to display server info
display_info() {
    echo ""
    print_info "=========================================="
    print_info "vLLM Server is running!"
    print_info "=========================================="
    echo ""
    echo "  API Endpoint: http://localhost:${PORT}/v1"
    echo "  Health Check: http://localhost:${PORT}/health"
    echo "  Model Info:   http://localhost:${PORT}/v1/models"
    echo ""
    echo "Test with curl:"
    echo "  curl http://localhost:${PORT}/v1/models"
    echo ""
    echo "View logs:"
    echo "  docker logs -f ${CONTAINER_NAME}"
    echo ""
    echo "Stop server:"
    echo "  docker stop ${CONTAINER_NAME}"
    echo ""
}

# Main execution
main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --model)
                MODEL="$2"
                shift 2
                ;;
            --port)
                PORT="$2"
                shift 2
                ;;
            --gpu-memory)
                GPU_MEMORY="$2"
                shift 2
                ;;
            --name)
                CONTAINER_NAME="$2"
                shift 2
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --model MODEL          Model to use (default: TinyLlama/TinyLlama-1.1B-Chat-v1.0)"
                echo "  --port PORT            Port to expose (default: 8000)"
                echo "  --gpu-memory RATIO     GPU memory utilization (default: 0.9)"
                echo "  --name NAME            Container name (default: vllm-server)"
                echo "  --help                 Show this help message"
                echo ""
                echo "Examples:"
                echo "  $0"
                echo "  $0 --model meta-llama/Llama-2-7b-chat-hf --port 8080"
                echo "  $0 --model mistralai/Mistral-7B-Instruct-v0.1 --gpu-memory 0.8"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    print_info "Starting vLLM Docker setup..."
    
    # Run checks
    check_docker
    
    # Cleanup existing container
    cleanup_container
    
    # Pull latest image
    pull_image
    
    # Run with GPU or CPU
    if check_nvidia_runtime; then
        run_with_gpu
    else
        run_with_cpu
    fi
    
    # Wait for server and display info
    if wait_for_server; then
        display_info
    else
        print_error "Failed to start server"
        exit 1
    fi
}

# Run main function
main "$@"
