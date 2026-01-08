# vLLM vs Ollama Performance Comparison

This project compares the inference performance of vLLM and Ollama servers with concurrent requests.

## Quick Start

### 1. Install Dependencies

```bash
pip install vllm openai aiohttp requests numpy matplotlib pandas jupyter
```

### 2. Start vLLM Server

Open a terminal and run:

```bash
# For a small test model
python -m vllm.entrypoints.openai.api_server --model facebook/opt-125m --port 8000

# Or for a better model (requires more VRAM)
python -m vllm.entrypoints.openai.api_server --model mistralai/Mistral-7B-v0.1 --port 8000
```

### 3. Install and Start Ollama

```bash
# Install Ollama from https://ollama.ai/

# Pull a model
ollama pull llama2
# or
ollama pull mistral

# Start server (usually runs automatically)
ollama serve
```

### 4. Run the Benchmark

```bash
jupyter notebook vllm_vs_ollama_benchmark.ipynb
```

Then run all cells step by step!

## What It Tests

- **Throughput**: Tokens generated per second
- **Latency**: Response time per request
- **Concurrency**: Performance with 1, 2, 4, 8 concurrent requests
- **Comparison**: Side-by-side metrics and visualizations

## Expected Results

- **vLLM**: Better throughput with concurrent requests (PagedAttention)
- **Ollama**: Easier setup, good for single requests

## Troubleshooting

- **Port conflicts**: Change ports if 8000 or 11434 are in use
- **CUDA errors**: Ensure GPU drivers are installed
- **OOM errors**: Use smaller models or reduce max_tokens
- **Connection refused**: Check that both servers are running

## Directory Structure

```
llm-comparison/
├── vllm_vs_ollama_benchmark.ipynb  # Main notebook
├── README.md                        # This file
└── vllm_vs_ollama_comparison.png   # Generated after running
```
