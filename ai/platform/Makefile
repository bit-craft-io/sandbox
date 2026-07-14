SHELL := /bin/bash
# ========================================
# menu
# ----------------------------------------
TASKS += \
	dify-pull \
	dify-up \
	dify-clean

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
			echo "COMPOSE_PROJECT_NAME=dify" >> dify/docker/.env; \
		else \
			echo "exist dify make skip"; \
		fi \
	fi

.PHONY: dify-up
dify-up:
	@if [ -f "dify/docker/docker-compose.yaml" ]; then \
		docker compose -f ./dify/docker/docker-compose.yaml up -d; \
	fi
.PHONY: dify-clean
dify-clean:
	@if [ -f "dify/docker/docker-compose.yaml" ]; then \
		docker compose -f ./dify/docker/docker-compose.yaml down -v; \
	fi
	@rm -rf ./dify/*
	@rm -rf ./dify/.git
