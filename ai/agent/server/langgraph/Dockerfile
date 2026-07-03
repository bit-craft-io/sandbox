FROM python:3.11-slim
WORKDIR /app
RUN pip install --no-cache-dir langchain-core langgraph "langgraph-cli[inmem]" \
    langchain-openai
COPY langgraph /app
CMD ["langgraph", "dev", "--host", "0.0.0.0", "--port", "8123"]
