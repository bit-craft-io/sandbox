# Game Server

## env value
```
_SANDBOX_DIR=/var/www/bc.sandbox
```

## install golang
```
cd /tmp
_GO_TAR_GZ=go1.26.2.linux-amd64.tar.gz
curl -LO https://go.dev/dl/$_GO_TAR_GZ
rm -rf /usr/local/go
sudo tar -C /usr/local -xzf $_GO_TAR_GZ
rm $_GO_TAR_GZ

cat << 'EOF' >> ~/.bashrc
# add $(date +'%Y.%m.%d') go lang
export GOROOT="/usr/local/go"
export GOPATH="$HOME/go"
export PATH="$GOROOT/bin:$GOPATH/bin:$PATH"
EOF

. ~/.bashrc

which go
go version
```

## setup dev tool
```
curl -sSfL https://raw.githubusercontent.com/aquaproj/aqua-installer/v4.0.2/aqua-installer | bash
[INFO] export PATH=${AQUA_ROOT_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/aquaproj-aqua}/bin:$PATH

cd $_SANDBOX_DIR/server
aqua install
```

## setup module
```
cd $_SANDBOX_DIR/server
make module
go list -f '{{.Dir}}' google.golang.org/protobuf
go list -f '{{.Dir}}' github.com/go-chi/chi/v5
go list -f '{{.Dir}}' agones.dev/agones/sdks/go
```

## vendor mode was used
```
cd $_SANDBOX_DIR/gs
# on
go mod tidy && go mod vendor && go build -mod=vendor ./...
# off
rm -rf vendor && go mod tidy
```

## make command
| コマンド                           | 内容                                    |
|:-------------------------------|:--------------------------------------|
| make proto                     | Protocol Buffersのコード生成                |
| make ent-new model_name=MItems | 新しいSchema（Entity）の雛形を作成               | 
| make ent                       | Schema定義からGoのコードを自動生成                 | 
| make atlas-diff file_name=test | SchemaとDBの差分を検出し、移行（Migration）ファイルを作成 | 
| make atlas-apply               | 作成された移行ファイルをデータベースに適用                 | 

## build Game Saver (=GS)
```
go version
cd /mnt/wsl/bc.sandbox.server
go mod init gs
docker build -t sample:latest .
```
