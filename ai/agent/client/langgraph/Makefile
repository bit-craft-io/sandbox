THIS_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
include $(THIS_DIR)../Makefile

.PHONY: cli-menu
cli-menu:
	$(VENV_PYTHON) menu.py

.PHONY: cli-health
cli-health:
	USE_LLM=false $(VENV_PYTHON) chat.py
	USE_LLM=false $(VENV_PYTHON) voice_stream.py

.PHONY: cli-chat
cli-chat:
	USE_LLM=true $(VENV_PYTHON) chat.py

.PHONY: cli-voice
cli-voice:
	USE_LLM=true $(VENV_PYTHON) voice_stream.py

