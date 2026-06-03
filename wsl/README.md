## 概要
- Docker Desktop for Windows (Kubernetes) と WSL2 のコンテナランタイムは別管理のため、<br>
WSL2 側で作成したコンテナイメージを利用できるよう連携設定を行う。

### 1. 同期設定の準備
```
__PROJECT_DIR=/var/www/bc.sandbox
sudo cp -p $__PROJECT_DIR/wsl/mount.bc.sandbox.server.service /etc/systemd/system/
sudo systemctl enable mount.bc.sandbox.server.service
sudo systemctl restart mount.bc.sandbox.server.service
```

### 2. 同期操作の実行
```
sudo systemctl start mount.bc.sandbox.server.service
sudo systemctl stop mount.bc.sandbox.server.service
```
