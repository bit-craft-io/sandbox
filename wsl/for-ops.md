# k8s

## pod app
### sync source code preparation
```
__PROJECT_DIR=/var/www/bc.sandbox
sudo cp -p $__PROJECT_DIR/wsl/mount.bc.sandbox.server.service /etc/systemd/system/
sudo systemctl enable mount.bc.sandbox.server.service
sudo systemctl restart mount.bc.sandbox.server.service
```

### sync source code execute
```
sudo systemctl start mount.bc.sandbox.server.service
sudo systemctl stop mount.bc.sandbox.server.service
```

### direnv
```
sudo apt install direnv
# for example
cd /tmp
echo "export __TMP_DIR=/tmp" > .envrc
direnv allow
echo $__TMP_DIR
```
