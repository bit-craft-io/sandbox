include ../Makefile

.PHONY: cli-menu
cli-menu:
	. ../.venv/bin/activate && python3 menu.py

.PHONY: cli-health
cli-health:
	USE_LLM=false python3 chat.py
	USE_LLM=false python3 voice_stream.py

.PHONY: cli-chat
cli-chat:
	USE_LLM=true python3 chat.py

.PHONY: cli-voice
cli-voice:
	USE_LLM=true python3 voice_stream.py

