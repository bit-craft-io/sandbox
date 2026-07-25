## 疎通確認
- WSLで実行

### 準備（共通ライブラリ・１回のみの実行）
```
sudo apt update
sudo apt install -y python3-venv python3-full
```
### 準備（Windows設定）
- Windows のマイクとスピーカーを WSL に連携
```
nano /mnt/c/Users/$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')/.wslconfig
```
```
[wsl2]
guiApplications=true
```
```
ctrl+X, Enter
```
### 準備（ライブラリ）
- 仮想環境にライブラリを追加（システム全体（グローバル環境）が壊れるのを防ぐため）
```
make setup
source .venv/bin/activate
```
### 疎通確認
```
cd ./client/langflow
make cli-await
```