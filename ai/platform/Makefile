include .env
SHELL := /bin/bash

DB_CONTAINER = db_postgres
DB_NAME = dify
DB_USER = postgres
COMPOSE_FILE = ./dify/docker/docker-compose.yaml
VOLUMES_DIR = ./dify/docker/volumes
# ========================================
# venv
# ----------------------------------------
ifndef ROOT_MK_INCLUDED
    ROOT_MK_INCLUDED := 1
    ROOT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
    export VENV_PYTHON := $(ROOT_DIR)/.venv/bin/python3
    export VENV_PIP    := $(ROOT_DIR)/.venv/bin/pip
endif

# ========================================
# menu
# ----------------------------------------
TASKS += \
	_exit \
	wsl-setup \
	wsl-info \
	wsl-clean \
	py-init \
	py-setup \
	dify-pull \
	dify-up \
	dify-down \
	dify-clean \
	dify-backup-all \
	dify-restore-all \
	dify-backup-list \
	dify-backup-clean

.PHONY: menu
menu:
#	@echo "select task:"
#	@select task in $(TASKS); do \
#		if [ -n "$$task" ]; then \
#			make --no-print-directory $$task; break; \
#		else \
#			echo "Invalid selection"; \
#		fi; \
#	done

	@echo "select task:"
	@i=1; \
	for t in $(TASKS); do \
		printf "%2d) %s\n" $$i "$$t"; \
		i=$$(($$i + 1)); \
	done; \
	read -p "??) " num; \
	task=$$(echo "$(TASKS)" | cut -d' ' -f$$num); \
	if [ -n "$$task" ]; then \
		make --no-print-directory $$task; \
	else \
		echo "Invalid selection"; \
	fi

.PHONY: _exit
_exit:
	@exit 0
# ========================================
# wsl
# ----------------------------------------
.PHONY: wsl-init
wsl-init:
	@echo "--- Install Ollama ---"
	@which ollama > /dev/null 2>&1 || (sudo apt-get install -y zstd && curl -fsSL https://ollama.com/install.sh | sh)
	sudo systemctl stop ollama 2>/dev/null || true
	sudo systemctl disable ollama 2>/dev/null || true

.PHONY: wsl-setup
wsl-setup:
	@echo "--- Pull LLM models ---"
	@pgrep ollama > /dev/null 2>&1 || (ollama serve &)
	sleep 3
	ollama pull $(__OLLAMA_MODEL)
	ollama list
	@pgrep ollama > /dev/null 2>&1 && pkill ollama || true

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
# command
# ----------------------------------------
.PHONY: py-init
py-init:
	sudo apt update
	sudo apt install -y python3 python3-pip python3-venv
	sudo apt install -y portaudio19-dev libpulse0

.PHONY: py-setup
py-setup:
	# 独立した Python 仮想環境（.venv）を作成
	python3 -m venv .venv
	# 音声認識・再生・音声合成・HTTPリクエスト用
	$(VENV_PIP) install speechrecognition pyaudio pyttsx3 requests
	# マルチメディアアプリ開発様（効果音・BGM再生に使用）
	$(VENV_PIP) install pygame
	# LangGraph（AIエージェントのグラフ構造制御）
	$(VENV_PIP) install langgraph langchain-core langchain-openai
	# CUI（ターミナル上の選択肢UI・1文字入力検知）
	$(VENV_PIP) install inquirerpy readchar
	# 高速ローカル音声認識（Whisper）・録音・音声判定・AI推論用
	$(VENV_PIP) install faster-whisper sounddevice numpy silero-vad torch
	# パッケージ管理・ビルド補助用
	$(VENV_PIP) install setuptools
	# Web API サーバー構築・起動用
	$(VENV_PIP) install fastapi uvicorn

# ========================================
# docker
# ----------------------------------------
DIFY_SECRET_KEY := $(__DIFY_SECRET_KEY)
.PHONY: dify-pull
dify-pull:
	@if [ ! -d "dify/.git" ]; then \
		echo "repository clone dify"; \
		git clone --branch 1.15.0 --depth 1 https://github.com/langgenius/dify.git dify; \
	else \
		echo "exist dify clone skip"; \
	fi
	@if [ -d "dify/docker" ]; then \
		if [ ! -f "dify/docker/.env" ]; then \
			echo "make .env from .env.example"; \
			cp dify/docker/.env.example dify/docker/.env; \
			echo "make .env from .env.example with custom project name"; \
			echo "COMPOSE_PROJECT_NAME=sandbox" >> dify/docker/.env; \
			echo "SECRET_KEY=$(DIFY_SECRET_KEY)" >> dify/docker/.env; \
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

# ========================================
# Dify バックアップ / リストア
# ----------------------------------------
# ディレクトリ構成:
#   backup/                最新バックアップの実体（git管理対象）
#   backup/history/<TS>/   世代ごとの履歴（git対象外）
#   backup/latest          history内最新へのsymlink（git対象外）
# ----------------------------------------
BACKUP_ROOT     := backup
HISTORY_ROOT    := $(BACKUP_ROOT)/history
TIMESTAMP       := $(shell date +%Y%m%d_%H%M%S)
BACKUP_DIR      := $(HISTORY_ROOT)/$(TIMESTAMP)
LATEST_LINK     := $(BACKUP_ROOT)/latest
GIT_BACKUP_DIR  := $(BACKUP_ROOT)
DB_NAME_PLUGIN  := dify_plugin

# ========================================
# Dify バックアップ
# ----------------------------------------
.PHONY: dify-backup-all
dify-backup-all:
	mkdir -p $(BACKUP_DIR)

	docker compose -f $(COMPOSE_FILE) exec $(DB_CONTAINER) pg_dump -U $(DB_USER) -d $(DB_NAME) > $(BACKUP_DIR)/dify_db.sql
	docker compose -f $(COMPOSE_FILE) exec $(DB_CONTAINER) pg_dump -U $(DB_USER) -d $(DB_NAME_PLUGIN) > $(BACKUP_DIR)/dify_plugin_db.sql

	docker compose -f $(COMPOSE_FILE) stop weaviate plugin_daemon
	sudo tar -czf $(BACKUP_DIR)/weaviate_data.tar.gz -C $(VOLUMES_DIR) weaviate
	sudo tar -czf $(BACKUP_DIR)/storage_data.tar.gz -C $(VOLUMES_DIR) app/storage
	# plugin_daemonは実行環境(cwd)を除外し、.difypkg本体等の軽量データのみ保存
	# cwdはdaemon起動時に自動再構築されるため保存不要（検証済み）
	sudo tar -czf $(BACKUP_DIR)/plugin_files.tar.gz \
		-C $(VOLUMES_DIR)/plugin_daemon plugin plugin_packages assets
	docker compose -f $(COMPOSE_FILE) start weaviate plugin_daemon

	sudo chown $(shell whoami):$(shell whoami) $(BACKUP_DIR)/*

	@rm -f $(LATEST_LINK)
	@ln -s history/$(TIMESTAMP) $(LATEST_LINK)

	# git管理対象のbackup/直下へ実ファイルとしてコピー（最新版のみ保持）
	@cp $(BACKUP_DIR)/*.sql $(BACKUP_DIR)/*.tar.gz $(GIT_BACKUP_DIR)/

	@echo "=========================================="
	@echo " backup done: $(BACKUP_DIR)"
	@echo " git-tracked copy -> $(GIT_BACKUP_DIR)/"
	@echo " (latest -> $(LATEST_LINK))"
	@echo "=========================================="

# ========================================
# Dify リストア
# 使い方:
#   make dify-restore-all                      # git管理対象(backup/直下)から復元
#   make dify-restore-all DIR=backup/latest     # ローカル最新から復元
#   make dify-restore-all DIR=backup/history/20260715_161500  # 世代指定
# ----------------------------------------
DIR ?= $(BACKUP_ROOT)
.PHONY: dify-restore-all
dify-restore-all:
	@test -f $(DIR)/dify_db.sql || (echo "[ERROR] backup not found: $(DIR)"; exit 1)

	docker compose -f $(COMPOSE_FILE) down
	docker compose -f $(COMPOSE_FILE) up -d db_postgres

	@echo "waiting for postgres..."
	@until docker compose -f $(COMPOSE_FILE) exec $(DB_CONTAINER) pg_isready -U $(DB_USER) > /dev/null 2>&1; do sleep 1; done

	docker compose -f $(COMPOSE_FILE) exec $(DB_CONTAINER) psql -U $(DB_USER) -c "DROP DATABASE IF EXISTS $(DB_NAME);"
	docker compose -f $(COMPOSE_FILE) exec $(DB_CONTAINER) psql -U $(DB_USER) -c "CREATE DATABASE $(DB_NAME);"
	@echo "restoring dify_db..."
	@cat $(DIR)/dify_db.sql | docker compose -f $(COMPOSE_FILE) exec -T $(DB_CONTAINER) psql -U $(DB_USER) -d $(DB_NAME) > /dev/null

	docker compose -f $(COMPOSE_FILE) exec $(DB_CONTAINER) psql -U $(DB_USER) -c "DROP DATABASE IF EXISTS $(DB_NAME_PLUGIN);"
	docker compose -f $(COMPOSE_FILE) exec $(DB_CONTAINER) psql -U $(DB_USER) -c "CREATE DATABASE $(DB_NAME_PLUGIN);"
	@echo "restoring dify_plugin..."
	@cat $(DIR)/dify_plugin_db.sql | docker compose -f $(COMPOSE_FILE) exec -T $(DB_CONTAINER) psql -U $(DB_USER) -d $(DB_NAME_PLUGIN) > /dev/null

	sudo tar -xzf $(DIR)/weaviate_data.tar.gz -C $(VOLUMES_DIR)
	sudo tar -xzf $(DIR)/storage_data.tar.gz -C $(VOLUMES_DIR)

	# plugin本体を配置。cwdはdaemon起動時に自動再構築される
	mkdir -p $(VOLUMES_DIR)/plugin_daemon
	sudo tar -xzf $(DIR)/plugin_files.tar.gz -C $(VOLUMES_DIR)/plugin_daemon

	docker compose -f $(COMPOSE_FILE) down
	docker compose -f $(COMPOSE_FILE) up -d

	@echo "=========================================="
	@echo " restore done from: $(DIR)"
	@echo " plugin_daemonのcwd自動再構築を待つ(数十秒〜)"
	@echo "=========================================="

# ========================================
# 補助
# ----------------------------------------
.PHONY: dify-backup-list
dify-backup-list:
	@ls -1 $(HISTORY_ROOT)/ 2>/dev/null || echo "no history backups"
	@echo $(HISTORY_ROOT)

# 7日以上前の世代を削除（history配下のみ、backup/直下とlatestは維持）
.PHONY: dify-backup-clean
dify-backup-clean:
	find $(HISTORY_ROOT)/ -maxdepth 1 -type d -mtime +7 -exec rm -rf {} \;
	@echo "[OK] old history backups (>7days) removed"

.DEFAULT:
	@echo "[WARN] target '$@' unknown"