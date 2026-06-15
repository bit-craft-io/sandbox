## 概要
- 学習用のリポジトリです
- This repository is a part of my professional portfolio, <br>
demonstrating my learning process and technical skills in software development.
 
## ディレクトリ構成
```
/                               # プロジェクト全体のルート（基盤管理・ツール管理の起点）
├── ai/                         # 生成AIパイプライン学習用（MPC、RAG、Agent）
├── docker/                     # 各種コンテナ定義（Spannerエミュレータなど）
├── envs/                       # 共通環境変数（ローカル開発環境設定など）
├── k8s/                        # K8s マニフェスト（kustomizeによる構成管理）
│ ├── base/                     # 基底となる共通定義
│ └── overlays/                 # 環境ごとの差分設定
├── server/                     # バックエンドアプリケーション（Go）
│ ├── cmd/                      # エントリポイント（APIサーバなど）
│ │ ├── app                     # 各種サーバ（Api、Agones、OpenMatchなど）
│ │ ├── sandbox                 # 色々お試し用
│ │ └── wizard                  # 便利ツール
│ ├── configs/                  # 設定ファイル群
│ ├── gen/                      # 自動生成コード（Protobufなど）
│ ├── internal/                 # 非公開のコアロジック
│ ├── migrations/               # DBマイグレーションファイル
│ ├── schema/                   # DBスキーマ定義（Spannerなど）
│ ├── Makefile                  # サービス個別の操作コマンド
│ └── .env                      # サービス個別のローカル環境変数
├── wsl/                        # WSL固有の設定やスクリプト
├── Makefile                    # プロジェクト全体の統合操作コマンド
├── aqua.yaml                   # 全体で統一された開発ツールの管理設定
└── .env                        # 全体共通のローカル環境変数
```

