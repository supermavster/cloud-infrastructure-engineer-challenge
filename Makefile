SHELL := /usr/bin/env bash
.SHELLFLAGS := -euo pipefail -c
.DEFAULT_GOAL := help

ENV ?= dev
TF_ROOTS := terraform
TF := terraform -chdir=terraform
CHECKOV_VERSION := 3.3.30
ENV_DIR := terraform/environments/$(ENV)

.PHONY: help init fmt fmt-check validate lint scan

help: ## Show this help
	@awk 'BEGIN {FS = ":.*## "} /^[a-z-]+:.*## / {printf "  %-12s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

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
