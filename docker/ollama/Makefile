OLLAMA_MODELS = ~/.ollama/models
SDXL_URL = https://huggingface.co/stabilityai/sdxl-turbo/resolve/main/sd_xl_turbo_1.0_fp16.safetensors

.PHONY: setup
setup:
	@echo "--- Install Ollama ---"
	@which ollama > /dev/null 2>&1 || (sudo apt-get install -y zstd && curl -fsSL https://ollama.com/install.sh | sh)
	sudo systemctl stop ollama 2>/dev/null || true
	sudo systemctl disable ollama 2>/dev/null || true

	@echo "--- Pull LLM models ---"
	@pgrep ollama > /dev/null 2>&1 || (ollama serve &)
	sleep 3
	ollama pull gemma4:e4b
	ollama list
	@pgrep ollama > /dev/null 2>&1 && pkill ollama || true

	@echo "--- Pull Image models ---"
	mkdir -p ~/.comfyui/models/checkpoints
	wget -nc -P ~/.comfyui/models/checkpoints $(SDXL_URL)

.PHONY: info
info:
	@echo "--- LLM models ---"
	@pgrep ollama > /dev/null 2>&1 || (ollama serve > /dev/null 2>&1 &)
	@sleep 3
	@ollama list
	@pgrep ollama > /dev/null 2>&1 && pkill ollama > /dev/null 2>&1 || true
	@echo "--- Image models ---"
	@ls -lh ~/.comfyui/models/checkpoints/ 2>/dev/null || echo "No image models found"

.PHONY: up
up:
	docker compose up -d

.PHONY: down
down:
	docker compose down

.PHONY: clean
clean:
	docker compose down -v
