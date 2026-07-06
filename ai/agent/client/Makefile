include ../Makefile
include .env

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
