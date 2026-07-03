include ../Makefile
include .env

export OLLAMA_MODELS = $(HOME)/.ollama/models
export COMFY_MODELS = $(HOME)/.comfyui/models
export SDXL_URL = https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/$(__COMFY_UI_MODEL)

.PHONY: setup
setup:
	@echo "--- Install Ollama ---"
	@which ollama > /dev/null 2>&1 || (sudo apt-get install -y zstd && curl -fsSL https://ollama.com/install.sh | sh)
	sudo systemctl stop ollama 2>/dev/null || true
	sudo systemctl disable ollama 2>/dev/null || true

	@echo "--- Pull LLM models ---"
	@pgrep ollama > /dev/null 2>&1 || (ollama serve &)
	sleep 3
	ollama pull $(__OLLAMA_MODEL)
	ollama list
	@pgrep ollama > /dev/null 2>&1 && pkill ollama || true

	@echo "--- Pull Image models ---"
	mkdir -p $(COMFY_MODELS)/checkpoints
	wget -nc -P $(COMFY_MODELS)/checkpoints $(SDXL_URL)

.PHONY: info
info:
	@echo "--- LLM models ---"
	@pgrep ollama > /dev/null 2>&1 || (ollama serve > /dev/null 2>&1 &)
	@sleep 3
	@ollama list
	@pgrep ollama > /dev/null 2>&1 && pkill ollama > /dev/null 2>&1 || true
	@echo "--- Image models ---"
	@ls -lh ~/.comfyui/models/checkpoints/ 2>/dev/null || echo "No image models found"
