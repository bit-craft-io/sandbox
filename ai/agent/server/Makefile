include .env
THIS_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
include $(THIS_DIR)../Makefile

export OLLAMA_MODELS = $(HOME)/.ollama/models
export COMFY_MODELS = $(HOME)/.comfyui/models
#export SDXL_URL = https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/$(__COMFY_UI_MODEL)

# ========================================
# menu
# ----------------------------------------
TASKS += \
	wsl-setup \
	wsl-info \
	wsl-clean \
	dc-restart \
	dc-up \
	dc-down \
	dc-clean \
	dc-build
# ========================================
# wsl
# ----------------------------------------
.PHONY: wsl-setup
wsl-setup:
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

#	@echo "--- Pull Image models ---"
#	mkdir -p $(COMFY_MODELS)/checkpoints
#	wget -nc -P $(COMFY_MODELS)/checkpoints $(SDXL_URL)

.PHONY: wsl-info
wsl-info:
	@echo "--- LLM models ---"
	@pgrep ollama > /dev/null 2>&1 || (ollama serve > /dev/null 2>&1 &)
	@sleep 3
	@ollama list
	@pgrep ollama > /dev/null 2>&1 && pkill ollama > /dev/null 2>&1 || true
#	@echo "--- Image models ---"
#	@ls -lh ~/.comfyui/models/checkpoints/ 2>/dev/null || echo "No image models found"

.PHONY: wsl-clean
wsl-clean:
	@echo "--- Cleaning up Ollama processes ---"
	@pgrep ollama > /dev/null 2>&1 || (echo "Starting ollama for cleanup..."; ollama serve > /dev/null 2>&1 & sleep 2)

	@echo "--- Deleting all Ollama models EXCEPT $(__OLLAMA_MODEL) ---"
	@sudo chown -R $$(whoami):$$(whoami) /home/guest/.ollama 2>/dev/null || true
	@if which ollama > /dev/null 2>&1; then \
		echo "Fetching downloaded models..."; \
		for model in $$(ollama list | tail -n +2 | awk '{print $$1}'); do \
			if [ "$$model" = "$(__OLLAMA_MODEL)" ]; then \
				echo "Keeping target model: $$model (Skipped)"; \
			else \
				echo "Deleting unused model: $$model..."; \
				ollama rm $$model; \
			fi \
		done; \
		echo "Cleanup completed (Only $(__OLLAMA_MODEL) remains)."; \
	else \
		echo "Ollama is not installed."; \
	fi

#	@echo "--- Deleting downloaded ComfyUI models ---"
#	@if [ -d ~/.comfyui/models/checkpoints/ ]; then \
#		echo "Removing all ComfyUI checkpoints..."; \
#		rm -rf ~/.comfyui/models/checkpoints/* && echo "ComfyUI checkpoints cleared."; \
#	else \
#		echo "No ComfyUI checkpoints directory found."; \
#	fi

	@echo "--- Stopping Ollama process ---"
	@pgrep ollama > /dev/null 2>&1 && pkill ollama || true

# ========================================
# docker
# ----------------------------------------
.PHONY: dc-restart
dc-restart:
	docker compose restart

.PHONY: dc-up
dc-up:
	docker compose up -d

.PHONY: dc-down
dc-down:
	docker compose down

.PHONY: dc-clean
dc-clean:
	docker compose down -v

.PHONY: dc-build
dc-build:
	docker compose up -d --build
