## 概要
- Go 学習用

## インストール
- Go
```
cd /tmp
wget https://go.dev/dl/go1.26.3.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.26.3.linux-amd64.tar.gz

echo '# add 2026.05.27 golang' >> ~/.bashrc
echo 'export PATH=/usr/local/go/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

go version
```

## 各種コマンド
| 対象     | 機能         | 例                                              |
|:-------|:-----------|:-----------------------------------------------|
| Go     | 環境構築       | make setup                                     |
|        | ビルド実行      | make build DIR=cmd/app/api NAME=api            | 
|        | プログラム実行    | make run NAME=api                              | 
|        | モジュール取得    | make download                                  |
|        | モジュール削除    | make remove                                    |
|        | モジュール追加    | make get protocolbuffers/protobuf/protoc@v35.0 |
|        | モジュール整理    | make tidy                                      |
| Protoc | スキーマ作成     | make proto-new NAME=dummy                      |
|        | コード生成      | make proto-gen                                 |
|        | 生成物削除      | make proto-gen-clean                           |
| Wrench | マイグレーション作成 | make migrate-new NAME=add_dummy_table          |
|        | マイグレーション取得 | make migrate-load                              |
|        | マイグレーション実行 | make migrate-up                                |
