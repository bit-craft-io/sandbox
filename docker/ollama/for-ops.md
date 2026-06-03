## WSLで作業
### モデルをダウンロード
```
curl -fsSL https://ollama.com/install.sh | sh
ollama pull gemma4:e2b
ollama pull gemma4:e4b
ollama list
sudo systemctl stop ollama
sudo systemctl disable ollama
```

### コンテナ起動
```
docker-compose up -d --remove-orphans
# docker-compose down
```

### コンテナ起動確認
```
http://localhost:4000
http://host.docker.internal:11434/api/tags
```

### コマンド
```
# ログを確認
docker logs -f ollama-base
# コンテナに入る
docker exec -it ollama-base sh
```
