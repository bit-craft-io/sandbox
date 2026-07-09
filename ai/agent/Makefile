SHELL := /bin/bash

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
#CLR_GREEN  := \033[1;32m
#CLR_CYAN   := \033[1;36m
#CLR_RESET  := \033[0m

TASKS = \
	_exit \
	py-init \
	py-setup

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
#menu:
#	@LIST=($(filter-out _exit, $(TASKS)) _exit); \
#	NUM_ITEMS=$${#LIST[@]}; \
#	CURSOR=0; \
#	while true; do \
#		clear; \
#		echo -e "$(CLR_GREEN)=== AI Agent Server Task Menu ===$(CLR_RESET)"; \
#		echo "Use Up/Down arrows and press Enter to select:"; \
#		echo "----------------------------------------"; \
#		for ((i=0; i<NUM_ITEMS; i++)); do \
#			if [ $$i -eq $$CURSOR ]; then \
#				echo -e "$(CLR_CYAN) > $${LIST[$$i]}$(CLR_RESET)"; \
#			else \
#				echo "   $${LIST[$$i]}"; \
#			fi; \
#		done; \
#		read -rsn1 key; \
#		if [[ $$key == $$'\x1b' ]]; then \
#			read -rsn2 -t 0.1 ext_key; \
#			if [[ $$ext_key == "[A" ]]; then \
#				CURSOR=$$(( (CURSOR - 1 + NUM_ITEMS) % NUM_ITEMS )); \
#			elif [[ $$ext_key == "[B" ]]; then \
#				CURSOR=$$(( (CURSOR + 1) % NUM_ITEMS )); \
#			fi; \
#		elif [[ $$key == "" ]]; then \
#			SELECTED=$${LIST[$$CURSOR]}; \
#			echo -e "\nRunning task: $(CLR_GREEN)$$SELECTED$(CLR_RESET)\n"; \
#			make --no-print-directory $$SELECTED; \
#			break; \
#		fi; \
#	done

.PHONY: _exit
_exit:
	@exit 0
#_exit:
#	@echo -e "$(CLR_CYAN)Bye!$(CLR_RESET)"
#	@exit 0

# ========================================
# command
# ----------------------------------------
.PHONY: py-init
py-init:
	sudo apt update
	sudo apt install -y python3 python3-pip python3-venv

.PHONY: py-setup
py-setup:
	python3 -m venv .venv
	$(VENV_PIP) install speechrecognition pyaudio pyttsx3 pygame requests
	$(VENV_PIP) install langgraph langchain-core langchain-openai
	$(VENV_PIP) install inquirerpy readchar
	$(VENV_PIP) install faster-whisper sounddevice numpy silero-vad torch
	$(VENV_PIP) install setuptools

.DEFAULT:
	@echo "[WARN] target '$@' unknown"