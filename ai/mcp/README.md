## MCP（Model Context Protocol）
- AIモデル（LLM）と外部のデータソースやツール（開発環境、データベース、ファイルなど）を<br />
安全かつ簡単に接続するための共通規格（プロトコル）

### MPCの設定
- Claude Desktop の開発者の設定<br />
※Laravelのコンテナを起動しておく必要がある
```
"mcpServers": {
  "sandbox": {
    "command": "wsl",
    "args": [
      "/var/www/bc.sandbox/ai/.venv/bin/python",
      "/var/www/bc.sandbox/ai/mcp/main.py"
    ]
  }
},
```
