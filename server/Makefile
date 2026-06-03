ifneq (,$(wildcard .env))
    include .env
    export $(shell sed 's/=.*//' .env)
endif

EXEC_DATE_STR=$$(date '+%Y/%m/%d %H:%M:%S')

DIR  ?= cmd/sandbox
NAME ?= sandbox

.PHONY: wizard
wizard:
	go run ./cmd/wizard

.PHONY: setup
setup: install-aqua
	@echo "----------------------------------------------------------------"
	@echo ">>> SETUP COMPLETED"
	@echo "----------------------------------------------------------------"

.PHONY: install-aqua
install-aqua:
	@if command -v aqua > /dev/null; then \
		echo "aqua is already installed."; \
	else \
		echo "Installing aqua..."; \
		curl -sSfL https://raw.githubusercontent.com/aquaproj/aqua-installer/v4.0.2/aqua-installer | bash; \
if ! grep -q "AQUA_ROOT_DIR" ~/.bashrc; then \
			echo "Adding aqua to ~/.bashrc..."; \
			echo "# add $$(date +%Y.%m.%d) aqua" >> ~/.bashrc; \
			echo 'export PATH=$${AQUA_ROOT_DIR:-$${XDG_DATA_HOME:-$$HOME/.local/share}/aquaproj-aqua}/bin:$$PATH' >> ~/.bashrc; \
			echo "Please run 'source ~/.bashrc' to reflect the changes."; \
		fi \
	fi
	aqua install

# ========================================
#  GoLang
# ----------------------------------------
.PHONY: build
build:
	@echo "Building $(DIR)..."
	go build -o bin/$(NAME) ./$(DIR)

.PHONY: run
run:
	@echo "Running bin/$(NAME)..."
	./bin/$(NAME)

# ========================================
#  GoLang module
# ----------------------------------------
.PHONY: download
download:
	go mod download

.PHONY: remove
remove:
	rm -rf vendor

pkg_args = $(filter-out get,$(MAKECMDGOALS))
.PHONY: get
ifneq ($(pkg_args),)
get:
	go get $(pkg_args)
	go mod tidy
else
get:
	@echo "usage  : make get <package>"
	@echo "example: make get gorm.io/gorm"
	@exit 1
endif
# magic
%:
	@:

.PHONY: tidy
tidy:
	go mod tidy

# ========================================
#  Proto
# ----------------------------------------
PROTO_SCHEMA_DIR := schema/proto
PROTO_GEN_DIR    := gen/proto
PROTO_OUT_GO     := $(PROTO_GEN_DIR)/go
PROTO_OUT_PHP    := $(PROTO_GEN_DIR)/php

.PHONY: proto-new
proto-new:
	@mkdir -p $(PROTO_SCHEMA_DIR)
	@sed -e 's/{{.PackageName}}/$(NAME)/g' \
	     -e 's/{{.MessageName}}/$(shell echo $(NAME) | perl -pe 's/(^|_)([a-z])/\U\2/g')/g' \
	     $(PROTO_SCHEMA_DIR)/template > $(PROTO_SCHEMA_DIR)/$(NAME).proto
	@echo "create $(PROTO_SCHEMA_DIR)/$(NAME).proto successfully"

.PHONY: proto-gen
proto-gen:
	@mkdir -p $(PROTO_OUT_GO) $(PROTO_OUT_PHP)
	protoc -I=$(PROTO_SCHEMA_DIR) \
		--go_out=$(PROTO_OUT_GO) --go_opt=paths=source_relative \
		--go-grpc_out=$(PROTO_OUT_GO) --go-grpc_opt=paths=source_relative \
		--php_out=$(PROTO_OUT_PHP) \
		$(shell find $(PROTO_SCHEMA_DIR) -name "*.proto")

.PHONY: proto-gen-clean
proto-gen-clean:
	@rm -rf $(PROTO_GEN_DIR)
	@echo "$(EXEC_DATE_STR) $(PROTO_GEN_DIR) directory removed"

# ========================================
#  Wrench
# ----------------------------------------

TIMESTAMP := $(shell date +%Y%m%d)

.PHONY: migrate-new
migrate-new:
	@next_seq=$$(ls migrations/*.up.sql 2>/dev/null | sed 's/.*\/0*\([0-9]*\)_.*/\1/' | sort -rn | head -n 1); \
	next_seq=$$(($$next_seq + 1)); \
	filename=$$(printf "migrations/%05d_%s_$(NAME).up.sql" $$next_seq $(TIMESTAMP)); \
	touch $$filename;

SPANNER_EMULATOR_HOST ?= localhost:9010

.PHONY: migrate-load
migrate-load:
ifeq ($(SPANNER_EMULATOR),true)
	SPANNER_EMULATOR_HOST=$(SPANNER_EMULATOR_HOST) wrench load --directory ./schema/spanner/_dev
else
	@echo "Emulator is not enabled. Skipping apply."
endif

.PHONY: migrate-up
migrate-up:
ifeq ($(SPANNER_EMULATOR), true)
	SPANNER_EMULATOR_HOST=$(SPANNER_EMULATOR_HOST) wrench migrate up
else
	wrench migrate up
endif

## ========================================
##  Ent
## ----------------------------------------
#ENT_SCHEMA_DIR      := schema/ent
#ENT_SCHEMA_TEMPLATE := $(ENT_SCHEMA_DIR)/schema.tmpl
#ENT_GEN_DIR         := gen/ent
#
#.PHONY: ent-new
#ent-new:
#	$(eval LOWER_NAME := $(shell echo $(NAME) | tr '[:upper:]' '[:lower:]'))
#	@mkdir -p $(ENT_SCHEMA_DIR)
#
#	# execute entc
#	go run -mod=mod entgo.io/ent/cmd/entc new \
#		--template $(ENT_SCHEMA_TEMPLATE) \
#		--target $(ENT_SCHEMA_DIR) $(NAME)
#
#	# execute rename
#	@if [ -f "$(ENT_SCHEMA_DIR)/$(LOWER_NAME).go" ]; then \
#		if [ "$(LOWER_NAME)" != "$(SNAKE_NAME)" ]; then \
#			echo "Renaming $(LOWER_NAME).go to $(SNAKE_NAME).go"; \
#			mv $(ENT_SCHEMA_DIR)/$(LOWER_NAME).go $(ENT_SCHEMA_DIR)/$(SNAKE_NAME).go; \
#		fi; \
#		# ref: schema.tmpl
#		sed -i 's/REPLACE_ME_SNAKE_CASE/$(SNAKE_NAME)/g' $(ENT_SCHEMA_DIR)/$(SNAKE_NAME).go; \
#	fi
#
#.PHONY: ent-gen
#ent-gen:
#	@mkdir -p $(ENT_GEN_DIR)
#
#	@if [ ! -f $(ENT_GEN_DIR)/empty.go ]; then \
#		echo "package ent" > $(ENT_GEN_DIR)/empty.go; \
#	fi
#
#	go run -mod=mod entgo.io/ent/cmd/entc generate --target ./$(ENT_GEN_DIR) ./$(ENT_SCHEMA_DIR)
#
#.PHONY: ent-gen-clean
#ent-gen-clean:
#	@rm -rf $(ENT_GEN_DIR)
#	@echo "$(EXEC_DATE_STR) $(ENT_GEN_DIR) directory removed"
#
## ========================================
##  Atlas
## ----------------------------------------
#MIGRATION_DIR := file://migrations
#ENT_SCHEMA_TO := ent://schema/ent
#ENT_CONTAINER := docker://mysql/8/ent
#
#.PHONY: atlas-hash
#atlas-hash:
#	@atlas migrate hash --dir $(MIGRATION_DIR)
#
#.PHONY: atlas-diff
#atlas-diff:
#	@atlas migrate diff $(NAME) \
#		--dir $(MIGRATION_DIR) \
#		--to $(ENT_SCHEMA_TO) \
#		--dev-url $(ENT_CONTAINER)
#	@make atlas-hash
#
#.PHONY: atlas-apply
#atlas-apply:
#	@atlas migrate apply \
#		--dir file://$(MIGRATION_DIR) \
#		--url $(DB_URL)
