.PHONY: py-init
py-init:
	sudo apt update
	sudo apt install -y python3 python3-pip python3-venv

.PHONY: py-setup
py-setup:
	python3 -m venv .venv
	. .venv/bin/activate && pip install speechrecognition pyaudio pyttsx3 pygame requests
	. .venv/bin/activate && pip install langgraph langchain-core langchain-openai
	. .venv/bin/activate && pip install inquirerpy readchar

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
