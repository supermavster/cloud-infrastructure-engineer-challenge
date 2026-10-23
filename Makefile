SHELL := /usr/bin/env bash
.SHELLFLAGS := -euo pipefail -c
.DEFAULT_GOAL := help

ENV ?= dev
TF_ROOTS := terraform terraform/bootstrap
TF_TEST_DIRS := $(TF_ROOTS) $(wildcard terraform/modules/*)
TF := terraform -chdir=terraform
BOOTSTRAP := terraform -chdir=terraform/bootstrap
REGION ?= us-east-1
CHECKOV_VERSION := 3.3.30
ENV_DIR := terraform/environments/$(ENV)

.PHONY: help bootstrap-plan bootstrap-apply backend-config init fmt fmt-check validate lint scan test

help: ## Show this help
	@awk 'BEGIN {FS = ":.*## "} /^[a-z-]+:.*## / {printf "  %-16s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

bootstrap-plan: ## Plan the state bucket (BUCKET=<globally unique name> [REGION=])
	@test -n "$(BUCKET)" || { echo "usage: make bootstrap-plan BUCKET=<globally-unique-name> [REGION=us-east-1]"; exit 1; }
	$(BOOTSTRAP) init -input=false
	$(BOOTSTRAP) plan -input=false -out=tfplan -var bucket_name=$(BUCKET) -var region=$(REGION)

bootstrap-apply: ## Apply the plan saved by bootstrap-plan (review it first)
	$(BOOTSTRAP) apply -input=false tfplan

backend-config: ## Write backend.hcl for ENV from the bootstrap outputs
	@test -d $(ENV_DIR) || { echo "unknown ENV '$(ENV)': $(ENV_DIR) does not exist"; exit 1; }
	@printf 'bucket       = "%s"\nkey          = "info-api/%s/terraform.tfstate"\nregion       = "%s"\nencrypt      = true\nuse_lockfile = true\n' \
		"$$($(BOOTSTRAP) output -raw bucket_name)" "$(ENV)" "$$($(BOOTSTRAP) output -raw region)" > $(ENV_DIR)/backend.hcl
	@echo "wrote $(ENV_DIR)/backend.hcl"

init: ## Initialise the remote backend for ENV (default: dev)
	@test -d $(ENV_DIR) || { echo "unknown ENV '$(ENV)': $(ENV_DIR) does not exist"; exit 1; }
	@test -f $(ENV_DIR)/backend.hcl || { echo "missing $(ENV_DIR)/backend.hcl: copy backend.hcl.example and fill it in"; exit 1; }
	$(TF) init -input=false -reconfigure -backend-config=environments/$(ENV)/backend.hcl

fmt: ## Rewrite Terraform files to canonical format
	terraform fmt -recursive terraform

fmt-check: ## Fail if any Terraform file is not formatted
	terraform fmt -check -recursive terraform

validate: ## Validate every Terraform root without touching a backend
	@for dir in $(TF_ROOTS); do \
		echo "validate $$dir"; \
		terraform -chdir=$$dir init -backend=false -input=false >/dev/null; \
		terraform -chdir=$$dir validate; \
	done

lint: ## Run tflint on every module
	tflint --init --config=$(CURDIR)/.tflint.hcl
	tflint --recursive --config=$(CURDIR)/.tflint.hcl

scan: ## Run checkov security checks (pinned version, no install needed)
	uvx --from checkov==$(CHECKOV_VERSION) checkov --config-file .checkov.yaml

test: ## Run terraform test (mocked AWS provider, no credentials needed)
	@for dir in $(TF_TEST_DIRS); do \
		echo "test $$dir"; \
		terraform -chdir=$$dir init -backend=false -input=false >/dev/null; \
		terraform -chdir=$$dir test; \
	done
