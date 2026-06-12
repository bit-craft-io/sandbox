## RAG（検索拡張生成：Retrieval-Augmented Generation）
- AI（大規模言語モデル）が回答する際に、<br />
外部データ（社内ドキュメントやナレッジベースなど）を検索し、<br />
取得した関連情報を参照しながら回答を生成する仕組み。

## 準備
- wsl の Ollama を起動、LLMを設定<br />
※ wslのディレクトリ参照
- docker の qdrant を起動<br />
※ docker/dockerのディレクトリ参照

## RAGシステムの構成要素

### Chunking（チャンキング）
- Webスクレイピングをしてサイト情報をベクトルに変換
```
pip install requests beautifulsoup4
```
- 情報を扱いやすい「塊（チャンク）」に分割・整理するプロセスや手法
```
pip install sentence-transformers
pip install langchain
pip install langchain-text-splitters
```

### Embedding（エンベディング、埋め込み表現）
- 単語、文章、画像などのデータを、AIが処理しやすい数値の羅列（ベクトル）に変換する技術

### Qdrant（RAGにおける意味検索（ベクトル検索）用のデータベース）
- ChunkデータとEmbeddingベクトルの保存先
```
pip install qdrant-client
```

### LLM統合
```
# 無料
pip install ollama
# 有料
# pip install anthropic
# pip install google-genai
```

### その他（ユーザインターフェース）
```
pip install prompt_toolkit
pip install rich
```
