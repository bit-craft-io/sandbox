include .env
SHELL := /bin/bash

DB_CONTAINER = db_postgres
DB_NAME = dify
DB_USER = postgres
COMPOSE_FILE = ./dify/docker/docker-compose.yaml
VOLUMES_DIR = ./dify/docker/volumes

# ========================================
# menu
# ----------------------------------------
TASKS += \
	wsl-setup \
	wsl-info \
	wsl-clean \
	dify-pull \
	dify-up \
	dify-down \
	dify-clean \
	dify-backup-all \
    dify-restore-all

.PHONY: menu
menu:
	@echo "select task:"
	@select task in $(TASKS); do \
		if [ -n "$$task" ]; then \
			make --no-print-directory $$task; break; \
		else \
			echo "Invalid selection"; \
		fi; \
	done

.PHONY: _exit
_exit:
	@exit 0
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

	@echo "--- Stopping Ollama process ---"
	@pgrep ollama > /dev/null 2>&1 && pkill ollama || true

# ========================================
# docker
# ----------------------------------------
.PHONY: dify-pull
dify-pull:
	@if [ ! -d "dify/.git" ]; then \
		echo "repository clone dify"; \
		git clone https://github.com/langgenius/dify.git dify; \
	else \
		echo "exist dify clone skip"; \
	fi
	@if [ -d "dify/docker" ]; then \
		if [ ! -f "dify/docker/.env" ]; then \
			echo "make .env from .env.example"; \
			cp dify/docker/.env.example dify/docker/.env; \
			echo "make .env from .env.example with custom project name"; \
			echo "COMPOSE_PROJECT_NAME=sandbox" >> dify/docker/.env; \
		else \
			echo "exist dify make skip"; \
		fi \
	fi

.PHONY: dify-up
dify-up:
	@if [ -f "dify/docker/docker-compose.yaml" ]; then \
		docker compose -f ./dify/docker/docker-compose.yaml up -d; \
		docker compose -f ./docker-compose.yaml up -d; \
	fi

.PHONY: dify-down
dify-down:
	@if [ -f "dify/docker/docker-compose.yaml" ]; then \
		docker compose -f ./dify/docker/docker-compose.yaml down; \
		docker compose -f ./docker-compose.yaml down; \
	fi

.PHONY: dify-clean
dify-clean:
	@if [ -f "dify/docker/docker-compose.yaml" ]; then \
		docker compose -f ./dify/docker/docker-compose.yaml down -v; \
		docker compose -f ./docker-compose.yaml down -v; \
	fi
	@sudo rm -rf ./dify

.PHONY: dify-backup-all
dify-backup-all:
	mkdir -p backup
	docker compose -f $(COMPOSE_FILE) exec $(DB_CONTAINER) pg_dump -U $(DB_USER) -d $(DB_NAME) > backup/dify_db.sql
	sudo tar -czf backup/weaviate_data.tar.gz -C $(VOLUMES_DIR) weaviate
	sudo tar -czf backup/storage_data.tar.gz -C $(VOLUMES_DIR) app/storage
	sudo tar --exclude='.venv' --exclude='__pycache__' --exclude='.uv-cache' -czf backup/plugin_daemon_data.tar.gz -C $(VOLUMES_DIR) plugin_daemon
	sudo chown $(shell whoami):$(shell whoami) backup/*
	@echo "all backup done: backup/"

.PHONY: dify-restore-all
dify-restore-all:
	docker compose -f $(COMPOSE_FILE) down
	docker compose -f $(COMPOSE_FILE) up -d db_postgres
	sleep 5
	docker compose -f $(COMPOSE_FILE) exec $(DB_CONTAINER) psql -U $(DB_USER) -c "DROP DATABASE IF EXISTS $(DB_NAME);"
	docker compose -f $(COMPOSE_FILE) exec $(DB_CONTAINER) psql -U $(DB_USER) -c "CREATE DATABASE $(DB_NAME);"
	cat backup/dify_db.sql | docker compose -f $(COMPOSE_FILE) exec -T $(DB_CONTAINER) psql -U $(DB_USER) -d $(DB_NAME)
	sudo tar -xzf backup/weaviate_data.tar.gz -C $(VOLUMES_DIR)
	sudo tar -xzf backup/storage_data.tar.gz -C $(VOLUMES_DIR)
	sudo tar -xzf backup/plugin_daemon_data.tar.gz -C $(VOLUMES_DIR)
	docker compose -f $(COMPOSE_FILE) down
	docker compose -f $(COMPOSE_FILE) up -d
	@echo "all restore done"

.DEFAULT:
	@echo "[WARN] target '$@' unknown"