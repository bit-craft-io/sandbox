## 概要
- 本リポジトリで管理しないため git clone で管理
### コマンド
- コンテナ作成
```
make dify-pull
make dify-up
```
- コンテナ削除
```
make dify-clean
```

- Git LFS 導入
```
cd /var/www/bc.sandbox
sudo apt update
sudo apt install git-lfs

git lfs install
git lfs version

git lfs track "ai/platform/backup/*.tar.gz"
git add .gitattributes
```