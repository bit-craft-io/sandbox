<style>pre {margin: 6px !important;padding: 6px 8px !important;}</style>
## 疎通確認

### 準備（共通ライブラリ・１回のみの実行）
- WSLで実行
```
sudo apt update
sudo apt install -y python3-venv python3-full

# 開発用パッケージ
sudo apt install -y libespeak-dev python3-dev gcc

# 音声関連のパッケージ
sudo apt install -y portaudio19-dev espeak-ng

# WSLとWindows間の音声入出力（マイク・スピーカー）連携用パッケージ
sudo apt install -y alsa-utils pulseaudio
```

### 準備（Windows設定）
- Windows のマイクとスピーカーを WSL に連携
- WSLで実行
```
nano /mnt/c/Users/$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')/.wslconfig
```
```
[wsl2]
guiApplications=true
audio=true
```
```
ctrl+X, Enter
```
### 準備（ライブラリ）
- 仮想環境にライブラリを追加
  - プロジェクトごとにライブラリのバージョンを隔離して、<br />
    システム全体（グローバル環境）が壊れるのを防ぐため
```
# 独立した Python 仮想環境（.venv）を作成
python3 -m venv .venv

# 仮想環境に入る（アクティベート）
source .venv/bin/activate

# 音声認識（STT）のラッパ・低レイヤーのオーディオ入出力・音声合成・HTTPクライアント
pip install speechrecognition pyaudio pyttsx3 requests

# 音声再生用
pip install pygame

# LangGraph のライブラリ
pip install langgraph langchain-core langchain-openai
```

### 疎通確認
```
# 文字データ
USE_LLM=false python3 client/chat.py
USE_LLM=true  python3 client/chat.py

# 音声データ
USE_LLM=false python3 client/voice_stream.py
USE_LLM=true  python3 client/voice_stream.py
```