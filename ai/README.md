### python3 をインストール
```
sudo apt update
sudo apt install python3 python3-pip python3-venv

which python3
which pip
dpkg -l | grep python3-venv

python3 -m venv .venv
source .venv/bin/activate

pip install mcp
which pip
```

### source .venv/bin/activate を自動化
```
vim .envrc
source .venv/bin/activate

direnv allow
```
