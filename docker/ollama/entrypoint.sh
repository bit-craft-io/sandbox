#!/bin/sh

mkdir -p /root/.ollama

echo "--- Copying from WSL (~/.ollama) to Container (/root/.ollama) ---"
cp -a /mnt/wsl_ollama/. /root/.ollama/

chown -R root:root /root/.ollama

/bin/ollama serve &

sleep 2
while ! ollama list > /dev/null 2>&1; do sleep 1; done

echo "--- Models recognized! ---"
ollama list

wait