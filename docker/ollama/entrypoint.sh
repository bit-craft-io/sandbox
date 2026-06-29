#!/bin/sh

/bin/ollama serve &

sleep 2
while ! ollama list > /dev/null 2>&1; do sleep 1; done

echo "--- Models recognized! ---"
ollama list

wait