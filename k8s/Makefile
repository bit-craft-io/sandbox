K8S_ID   ?= id-game-server
K8S_NS   ?= k8s
GS_NAME  ?= sample
GS_DIR   ?= /mnt/wsl/bc.sandbox.server/cmd/sandbox
#GS_TAG   ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo "latest")
GS_TAG   ?= latest
GS_IMG   ?= $(GAME_SERVER_NAME):$(GAME_SERVER_TAG)
CMD_OPT  ?= --server-side --force-conflicts
#CMD_OPT  ?=
PORT_HST ?= 8081
PORT_GST ?= 8081
TARGET_K := ./overlays/local
TARGET_DIR := cmd/sandbox

.PHONY: setup
setup: install-kustomize
	@echo "--- SETUP COMPLETED ---"

.PHONY: install-kustomize
install-kustomize:
	@if command -v kustomize > /dev/null; then \
		echo "kustomize is already installed."; \
	else \
		echo "Installing kustomize..."; \
		cd /tmp && curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash && sudo mv kustomize /usr/local/bin/; \
	fi

.PHONY: publish
publish:
	@echo ">>> [STAGE 1/5] BUILDING GO BINARY"
	$(MAKE) build-go
	#@echo ">>> [STAGE 2/5] BUILDING DOCKER IMAGE"
	#$(MAKE) docker-build
	@echo ">>> [STAGE 3/5] PURGING OLD RESOURCES"
	$(MAKE) purge
	@echo ">>> [STAGE 4/5] APPLYING K8S MANIFESTS"
	$(MAKE) apply
	@echo ">>> [STAGE 5/5] CHECKING DEPLOYMENT STATUS"
	$(MAKE) status
	@echo ">>> PUBLISH COMPLETED SUCCESSFULLY"

# --- Sub Tasks ---
.PHONY: build-go
build-go:
	@echo "--- GO: TIDYING MODULES ---"
	cd $(GAME_SERVER_DIR) && go mod tidy
	@echo "--- DOCKER: PRUNING DANGLING IMAGES ---"
	-docker image prune -f

.PHONY: docker-build
docker-build:
	@echo "--- BUILDING IMAGE [$(GAME_SERVER_IMG)] ---"
	docker build -t $(GAME_SERVER_IMG) -f cmd/Dockerfile --build-arg TARGET_DIR=$(SERVER_DIR) .

.PHONY: purge
purge:
	@echo "--- K8S: PURGING ONLY THE GAMESERVER ---"
	-kubectl delete gs $(K8S_IDENTIFIER) -n $(K8S_NAMESPACE) --grace-period=0 --force
	@echo "--- WAITING FOR GS TO BE GONE ---"
	-kubectl wait --for=delete gs/$(K8S_IDENTIFIER) -n $(K8S_NAMESPACE) --timeout=30s

.PHONY: apply
apply:
	@echo "--- APPLYING [$(TARGET_KUSTOMIZE)] ---"
	# Kustomizeのエディット機能で、ビルドしたタグを動的にマニフェストへ注入する
	cd $(TARGET_KUSTOMIZE) && kustomize edit set image img-backend=$(GAME_SERVER_IMG)
	kubectl apply $(APPLY_OPTION) -k $(TARGET_KUSTOMIZE)

.PHONY: status
status:
	@echo "--- K8S: FETCHING GAMESERVER STATUS ---"
	kubectl get gs $(K8S_IDENTIFIER) -n $(K8S_NAMESPACE)
	@echo "--- K8S: FETCHING POD STATUS ---"
	kubectl get pods -n $(K8S_NAMESPACE) -l agones.dev/gameserver=$(K8S_IDENTIFIER)

#.PHONY: delete
#delete:
#	@echo "--- K8S: DELETING RESOURCES ---"
#	kubectl delete $(CMD_OPT) -k $(TARGET_K)

#wait-delete:
#	@echo "--- K8S: WAITING FOR GAMESERVER TO BE TERMINATED ---"
#	-kubectl wait --for=delete server/$(K8S_ID) -n $(K8S_NS) --timeout=60s

#tunnel:
#	@echo "--- $(LOCAL_PORT):$(APP_PORT) トンネル開通や、ワレ！ ---"
#	kubectl port-forward -n $(K8S_NS) pod/$(K8S_ID) $(PORT_HST):$(PORT_GST)

.PHONY: check-tunnel
check-tunnel:
	@echo "--- SYSTEM: CHECKING PORT-FORWARD PROCESS ---"
	@ps aux | grep "kubectl port-forward" | grep -v grep || echo "Warning: Port-forward is not running."

.PHONY: check-nodeport
check-nodeport:
	@echo "--- INFO: NODEPORT 30180 IS ACTIVE ---"
	@echo "Access from Laravel via: http://host.docker.internal:30180"
	kubectl get svc gs-http-service -n $(K8S_NAMESPACE)

.PHONY: restart
restart:
	@echo "--- K8S: RESTARTING GAMESERVER (DELETE & RECREATE) ---"
	-kubectl delete gs $(K8S_IDENTIFIER) -n $(K8S_NAMESPACE) --timeout=10s

.PHONY: logs
logs:
	@echo "--- K8S: STREAMING LOGS (TAIL:100) ---"
	kubectl logs -l app=$(K8S_IDENTIFIER) -n $(K8S_NAMESPACE) --tail=100 -f

