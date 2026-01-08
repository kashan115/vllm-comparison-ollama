# vLLM Docker Setup Guide

This guide provides step-by-step instructions for running vLLM using Docker.

## Prerequisites

- Docker installed on your system
- NVIDIA GPU with CUDA support (recommended)
- NVIDIA Container Toolkit (for GPU support)

## Quick Start

### Option 1: Using Docker Run (Simple)

```bash
# Pull the official vLLM Docker image
docker pull vllm/vllm-openai:latest

# Run vLLM with a model (example: TinyLlama)
docker run --runtime nvidia --gpus all \
    -v ~/.cache/huggingface:/root/.cache/huggingface \
    -p 8000:8000 \
    --ipc=host \
    vllm/vllm-openai:latest \
    --model TinyLlama/TinyLlama-1.1B-Chat-v1.0
```

### Option 2: Using Docker Compose (Recommended)

See [docker-compose.yml](#docker-compose-file) below.

---

## Step-by-Step Instructions

### Step 1: Install NVIDIA Container Toolkit (GPU Support)

If you haven't installed the NVIDIA Container Toolkit:

```bash
# Add NVIDIA package repositories
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

# Install nvidia-container-toolkit
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

# Restart Docker daemon
sudo systemctl restart docker
```

### Step 2: Pull the vLLM Docker Image

```bash
# Pull the latest vLLM image with OpenAI-compatible API
docker pull vllm/vllm-openai:latest

# Or pull a specific version
docker pull vllm/vllm-openai:v0.6.0
```

### Step 3: Run vLLM Container

#### Basic Example (TinyLlama)

```bash
docker run -d \
    --name vllm-server \
    --runtime nvidia \
    --gpus all \
    -v ~/.cache/huggingface:/root/.cache/huggingface \
    -p 8000:8000 \
    --ipc=host \
    vllm/vllm-openai:latest \
    --model TinyLlama/TinyLlama-1.1B-Chat-v1.0 \
    --host 0.0.0.0 \
    --port 8000
```

#### With Custom Parameters

```bash
docker run -d \
    --name vllm-server \
    --runtime nvidia \
    --gpus all \
    -v ~/.cache/huggingface:/root/.cache/huggingface \
    -p 8000:8000 \
    --ipc=host \
    vllm/vllm-openai:latest \
    --model meta-llama/Llama-2-7b-chat-hf \
    --host 0.0.0.0 \
    --port 8000 \
    --tensor-parallel-size 1 \
    --max-model-len 4096 \
    --gpu-memory-utilization 0.9
```

### Step 4: Verify the Server is Running

```bash
# Check container logs
docker logs vllm-server

# Test the API
curl http://localhost:8000/v1/models

# Or test with a completion request
curl http://localhost:8000/v1/completions \
    -H "Content-Type: application/json" \
    -d '{
        "model": "TinyLlama/TinyLlama-1.1B-Chat-v1.0",
        "prompt": "What is the capital of France?",
        "max_tokens": 100,
        "temperature": 0.7
    }'
```

### Step 5: Test with Python Client

```python
from openai import OpenAI

# Initialize client pointing to vLLM
client = OpenAI(
    base_url="http://localhost:8000/v1",
    api_key="EMPTY"  # vLLM doesn't require an API key
)

# Create a completion
response = client.completions.create(
    model="TinyLlama/TinyLlama-1.1B-Chat-v1.0",
    prompt="What is the capital of France?",
    max_tokens=100,
    temperature=0.7
)

print(response.choices[0].text)
```

---

## Docker Compose File

Create a `docker-compose.yml` file:

```yaml
version: '3.8'

services:
  vllm:
    image: vllm/vllm-openai:latest
    container_name: vllm-server
    runtime: nvidia
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - CUDA_VISIBLE_DEVICES=0
    volumes:
      - ~/.cache/huggingface:/root/.cache/huggingface
    ports:
      - "8000:8000"
    shm_size: '16gb'
    command:
      - --model
      - TinyLlama/TinyLlama-1.1B-Chat-v1.0
      - --host
      - 0.0.0.0
      - --port
      - "8000"
      - --tensor-parallel-size
      - "1"
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
```

Run with:

```bash
docker-compose up -d
```

---

## Common vLLM Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `--model` | HuggingFace model ID | `TinyLlama/TinyLlama-1.1B-Chat-v1.0` |
| `--host` | Server host | `0.0.0.0` |
| `--port` | Server port | `8000` |
| `--tensor-parallel-size` | Number of GPUs for tensor parallelism | `1`, `2`, `4` |
| `--max-model-len` | Maximum sequence length | `2048`, `4096` |
| `--gpu-memory-utilization` | GPU memory utilization (0.0-1.0) | `0.9` |
| `--dtype` | Data type | `auto`, `float16`, `bfloat16` |
| `--max-num-seqs` | Maximum number of sequences | `256` |

---

## Different Models Examples

### 1. TinyLlama (1.1B)
```bash
docker run -d --runtime nvidia --gpus all \
    -v ~/.cache/huggingface:/root/.cache/huggingface \
    -p 8000:8000 --ipc=host \
    vllm/vllm-openai:latest \
    --model TinyLlama/TinyLlama-1.1B-Chat-v1.0
```

### 2. Llama 2 7B
```bash
docker run -d --runtime nvidia --gpus all \
    -v ~/.cache/huggingface:/root/.cache/huggingface \
    -p 8000:8000 --ipc=host \
    vllm/vllm-openai:latest \
    --model meta-llama/Llama-2-7b-chat-hf
```

### 3. Mistral 7B
```bash
docker run -d --runtime nvidia --gpus all \
    -v ~/.cache/huggingface:/root/.cache/huggingface \
    -p 8000:8000 --ipc=host \
    vllm/vllm-openai:latest \
    --model mistralai/Mistral-7B-Instruct-v0.1
```

### 4. Qwen 7B
```bash
docker run -d --runtime nvidia --gpus all \
    -v ~/.cache/huggingface:/root/.cache/huggingface \
    -p 8000:8000 --ipc=host \
    vllm/vllm-openai:latest \
    --model Qwen/Qwen2-7B-Instruct
```

---

## Useful Docker Commands

```bash
# View running containers
docker ps

# View logs
docker logs vllm-server

# Follow logs in real-time
docker logs -f vllm-server

# Stop the container
docker stop vllm-server

# Start the container
docker start vllm-server

# Remove the container
docker rm vllm-server

# Check GPU usage inside container
docker exec vllm-server nvidia-smi

# Access container shell
docker exec -it vllm-server bash
```

---

## Troubleshooting

### Issue: CUDA Out of Memory

**Solution 1:** Reduce GPU memory utilization
```bash
--gpu-memory-utilization 0.7
```

**Solution 2:** Reduce max model length
```bash
--max-model-len 2048
```

**Solution 3:** Use a smaller model or quantization

### Issue: Container exits immediately

Check logs:
```bash
docker logs vllm-server
```

Common causes:
- Model not found in HuggingFace
- Insufficient GPU memory
- NVIDIA runtime not properly configured

### Issue: Slow model loading

First run downloads the model. Monitor with:
```bash
docker logs -f vllm-server
```

Models are cached in `~/.cache/huggingface`

---

## Performance Tips

1. **Use `--ipc=host`**: Improves shared memory performance
2. **Set appropriate `--max-num-seqs`**: Balance throughput vs latency
3. **Use `--gpu-memory-utilization 0.9`**: Maximize GPU usage
4. **Enable tensor parallelism**: For multi-GPU setups
   ```bash
   --tensor-parallel-size 2
   ```

---

## CPU-Only Mode (No GPU)

If you don't have a GPU:

```bash
docker run -d \
    --name vllm-server \
    -v ~/.cache/huggingface:/root/.cache/huggingface \
    -p 8000:8000 \
    vllm/vllm-openai:latest \
    --model TinyLlama/TinyLlama-1.1B-Chat-v1.0 \
    --host 0.0.0.0 \
    --port 8000 \
    --device cpu
```

**Note:** CPU inference is much slower than GPU inference.

---

## Next Steps

- Check the main [README.md](README.md) for benchmark results
- See [vllm_vs_ollama_fair_comparison.ipynb](vllm_vs_ollama_fair_comparison.ipynb) for comparison notebooks
- Visit [vLLM Documentation](https://docs.vllm.ai/) for advanced configuration

---

## Resources

- [vLLM GitHub](https://github.com/vllm-project/vllm)
- [vLLM Documentation](https://docs.vllm.ai/)
- [Docker Hub - vLLM](https://hub.docker.com/r/vllm/vllm-openai)
- [HuggingFace Models](https://huggingface.co/models)
