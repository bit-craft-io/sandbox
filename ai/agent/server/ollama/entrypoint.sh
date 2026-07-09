#!/bin/sh

/bin/ollama serve &
SERVE_PID=$!

sleep 2
while ! ollama list > /dev/null 2>&1; do sleep 1; done

echo "Models recognized!"
ollama list

echo "Warming up model: ${__OLLAMA_MODEL}"
( echo hi | ollama run "${__OLLAMA_MODEL}" > /tmp/warmup.log 2>&1 )
echo "Warmup completed (exit: $?)"
cat /tmp/warmup.log

wait $SERVE_PID