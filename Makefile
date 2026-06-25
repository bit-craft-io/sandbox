include .env
export

LIST_ENV := local dev stg prd
DIR_ENV  := $(if $(filter $(ENV),$(LIST_ENV)),$(ENV),local)

APP      := default
LIST_APP := api director openmatch game
IMG_NAME := $(if $(filter $(APP),$(LIST_APP)),$(APP),default)

DIR_BUILD_APP       := cmd/app/$(APP)
IMG_CONTAINER       := $(IMG_NAME):$(APP_TAG)
KUSTOMIZE_YML_APP   := k8s/overlays/$(DIR_ENV)/$(APP)
KUSTOMIZE_YML_INFRA := k8s/overlays/$(DIR_ENV)/infra
LIST_KUBE_TARGET    := bit-craft agones api director openmatch game

# ========================================
# command result check
# ----------------------------------------
CLR_GREEN   := \033[32m
CLR_RED     := \033[31m
CLR_YELLOW  := \033[33m
CLR_RESET   := \033[0m
MSG_SUCCESS := $(CLR_GREEN)SUCCESS$(CLR_RESET)
MSG_ERROR   := $(CLR_RED)ERROR$(CLR_RESET)
define check_result
	&&   echo "$(CLR_GREEN)  SUCCESS: $@$(CLR_RESET)" \
	|| { echo "$(CLR_RED)  FAILED: $@$(CLR_RESET)"; exit 1; }
endef

# ========================================
# command k8s
# ----------------------------------------
.PHONY: init-env
init-env:
	@echo "----------------------------------------------------------------"
	@echo ">>> INITIALISE ENVIRONMENT"
	@echo "----------------------------------------------------------------"
	@if command -v kustomize > /dev/null; then \
		echo "kustomize is already installed."; \
	else \
		echo "Installing kustomize..."; \
		cd /tmp && curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash && sudo mv kustomize /usr/local/bin/; \
	fi

.PHONY: init-kube-infra
init-kube-infra:
	@echo "----------------------------------------------------------------"
	@echo ">>> APPLYING INFRA"
	@echo "----------------------------------------------------------------"
	kubectl apply $(APPLY_OPTION) -k $(KUSTOMIZE_YML_INFRA)

.PHONY: deploy
deploy:
	$(MAKE) dev-check-export
	@echo "----------------------------------------------------------------"
	@echo ">>> DEPLOYING $(APP)"
	@echo "----------------------------------------------------------------"
	$(MAKE) build-container
	$(MAKE) kube-apply
	kubectl rollout status deployment/deploy-$(APP) -n $(APPLY_NAMESPACE)
	$(MAKE) dev-kube-forward
	$(MAKE) kube-status
	@echo "----------------------------------------------------------------"
	@echo "$(CLR_GREEN)>>> ALL STEPS COMPLETED SUCCESSFULLY!$(CLR_RESET)"
	@echo "----------------------------------------------------------------"

.PHONY: redeploy
redeploy:
	@echo "----------------------------------------------------------------"
	@echo ">>> REDEPLOYING $(APP)"
	@echo "----------------------------------------------------------------"
	$(MAKE) build-container
	$(MAKE) kube-restart
	kubectl rollout status deployment/deploy-$(APP) -n $(APPLY_NAMESPACE)
	$(MAKE) dev-kube-forward
	$(MAKE) kube-status
	@echo "----------------------------------------------------------------"
	@echo "$(CLR_GREEN)>>> ALL STEPS COMPLETED SUCCESSFULLY!$(CLR_RESET)"
	@echo "----------------------------------------------------------------"

.PHONY: build-container
build-container:
	@echo "----------------------------------------------------------------"
	@echo ">>> BUILDING IMAGE [$(IMG_CONTAINER)]"
	@echo "----------------------------------------------------------------"
	cd server && docker build -t $(IMG_CONTAINER) -f $(DIR_BUILD_APP)/Dockerfile --build-arg TARGET_DIR=$(DIR_BUILD_APP) . \
		$(call check_result)

.PHONY: kube-apply
kube-apply:
	@echo "----------------------------------------------------------------"
	@echo ">>> APPLYING [$(KUSTOMIZE_YML_APP)]"
	@echo "----------------------------------------------------------------"
	kubectl create configmap $(APP)-env \
		--from-env-file=server/$(DIR_BUILD_APP)/.env \
		--dry-run=client -o yaml | \
		kubectl apply -f - -n $(APPLY_NAMESPACE)
	export KUSTOMIZE_APP_NAME=$(APP); \
	export KUSTOMIZE_IMG_NAME=$(IMG_CONTAINER); \
	kustomize build $(KUSTOMIZE_YML_APP) | envsubst | \
	kubectl apply $(APPLY_OPTION) -f - -n $(APPLY_NAMESPACE) \
		$(call check_result)

.PHONY: kube-restart
kube-restart:
	@echo "----------------------------------------------------------------"
	@echo ">>> RESTARTING APP [$(APP)]"
	@echo "----------------------------------------------------------------"
	kubectl rollout restart deployment -l app=$(APP) -n $(APPLY_NAMESPACE) \
		$(call check_result)

.PHONY: kube-status
kube-status:
	@echo "----------------------------------------------------------------"
	@echo ">>> K8S STATUS [$(APPLY_NAMESPACE)] : $(APP)"
	@echo "----------------------------------------------------------------"
	kubectl get all -n $(APPLY_NAMESPACE)

	@echo ""
	@echo "----------------------------------------------------------------"
	@echo " DETAILED POD STATUS ($(APP))"
	kubectl get pod -l app=$(APP) -n $(APPLY_NAMESPACE) -o wide

	@echo ""
	@echo "----------------------------------------------------------------"
	@echo " LOGS (LATEST 10 LINES)"
	-kubectl logs -l app=$(APP) -n $(APPLY_NAMESPACE) --tail=10 --max-log-requests=1

.PHONY: kube-clean
kube-clean:
	@echo "----------------------------------------------------------------"
	@echo ">>> CLEANING K8S RESOURCES (FULL PURGE)"
	@echo "----------------------------------------------------------------"
	@echo ">>> KILLING EVERYTHING FOR APP: $(APP) IN $(APPLY_NAMESPACE)"
	-kubectl delete deploy -l app=$(APP) -n $(APPLY_NAMESPACE)
	-kubectl delete svc    -l app=$(APP) -n $(APPLY_NAMESPACE)
	@echo "--- WAITING FOR PODS TO BE GONE ---"
	-kubectl wait --for=delete pod -l app=$(APP) -n $(APPLY_NAMESPACE) --timeout=10s
	@echo "----------------------------------------------------------------"
	@echo ">>> CLEANING COMPLETED SUCCESSFULLY"
	@echo "----------------------------------------------------------------"

.PHONY: kube-clean-all
kube-clean-all:
	-for svc in $$(kubectl get svc -n agones-system -o jsonpath='{.items[*].metadata.name}' 2>/dev/null); do \
		kubectl patch svc $$svc -n agones-system -p '{"metadata":{"finalizers":[]}}' --type=merge; \
	done
	-kubectl delete ns $(APPLY_NAMESPACE) --ignore-not-found
	-kubectl delete -k $(KUSTOMIZE_YML_INFRA) --ignore-not-found
	-kubectl get all -A | grep -E "$(shell echo $(LIST_KUBE_TARGET) | sed 's/ /|/g')" || echo "CLEAN COMPLETE, WARE!"

# ========================================
# development
# ----------------------------------------
.PHONY: dev-check-export
dev-check-export:
	@echo "----------------------------------------------------------------"
	@echo ">>> ENVIRONMENT VARIABLE DUMP (REAL SHELL CHECK)"
	@echo "----------------------------------------------------------------"
	@echo "[Environment]"
	@echo -n "  ENV                 : " && printenv ENV || echo "NOT EXPORTED"
	@echo ""
	@echo "[Container]"
	@echo -n "  IMG_CONTAINER       : " && printenv IMG_CONTAINER || echo "NOT EXPORTED"
	@echo -n "  DIR_BUILD_APP       : " && printenv DIR_BUILD_APP || echo "NOT EXPORTED"
	@echo ""
	@echo "[Kustomize]"
	@echo -n "  KUSTOMIZE_YML_APP   : " && printenv KUSTOMIZE_YML_APP || echo "NOT EXPORTED"
	@echo -n "  KUSTOMIZE_YML_INFRA : " && printenv KUSTOMIZE_YML_INFRA || echo "NOT EXPORTED"

.PHONY: dev-kube-forward
dev-kube-forward:
	nohup kubectl port-forward svc/svc-$(APP) 10080:8080 -n $(APPLY_NAMESPACE) --address 0.0.0.0 > /dev/null 2>&1 &
