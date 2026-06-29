## 概要
- LLM 用

## 準備
- Ollama
  - wsl で起動 
```
sudo apt-get install zstd
curl -fsSL https://ollama.com/install.sh | sh
ollama pull gemma4:e2b
ollama pull gemma4:e4b
ollama list
```

```
sudo systemctl stop ollama
sudo systemctl disable ollama
```
