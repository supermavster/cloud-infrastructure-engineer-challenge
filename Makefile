SHELL := /usr/bin/env bash
.SHELLFLAGS := -euo pipefail -c
.DEFAULT_GOAL := help

ENV ?= dev
TF_ROOTS := terraform terraform/bootstrap
DOC_DIRS := terraform terraform/bootstrap $(wildcard terraform/modules/*)
TF_TEST_DIRS := terraform/bootstrap $(wildcard terraform/modules/*)
ENVS := dev prod
TF := terraform -chdir=terraform
BOOTSTRAP := terraform -chdir=terraform/bootstrap
REGION ?= us-east-1
CHECKOV_VERSION := 3.3.30
ACTIONLINT_VERSION := 1.7.12.25
FUNCTION_DIR := functions/info
BUILD_DIR := build/functions/info
ENV_DIR := terraform/environments/$(ENV)
TFVARS := environments/$(ENV)/terraform.tfvars

.PHONY: help bootstrap-plan bootstrap-apply backend-config init fmt fmt-check validate lint scan test function-lint function-test function-integration docs actionlint local-up local-down local-invoke build check plan apply destroy verify logs

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

test: ## Run terraform test: every module, then the root once per environment (mocked AWS, no credentials)
	@for dir in $(TF_TEST_DIRS); do \
		echo "test $$dir"; \
		terraform -chdir=$$dir init -backend=false -input=false >/dev/null; \
		terraform -chdir=$$dir test; \
	done
	@terraform -chdir=terraform init -backend=false -input=false >/dev/null
	@for env in $(ENVS); do \
		echo "test terraform ($$env)"; \
		terraform -chdir=terraform test -var-file=environments/$$env/terraform.tfvars; \
	done

docs: ## Regenerate the Terraform README tables (needs terraform-docs 0.24.0)
	@for dir in $(DOC_DIRS); do \
		terraform-docs --config .terraform-docs.yml $$dir >/dev/null; \
	done

actionlint: ## Lint the GitHub Actions workflows (pinned version, no install needed)
	uvx --from actionlint-py==$(ACTIONLINT_VERSION) actionlint

function-lint: ## Lint and format-check the Lambda function
	cd $(FUNCTION_DIR) && uv run ruff check . && uv run ruff format --check .

function-test: ## Run the Lambda unit tests (no database needed)
	cd $(FUNCTION_DIR) && uv run pytest -m "not integration"

function-integration: ## Run the integration tests against the PostgreSQL in the DB_* variables
	cd $(FUNCTION_DIR) && uv run pytest -m integration

local-up: ## Start a local PostgreSQL in Docker (creates local/.env from the example)
	@test -f local/.env || cp local/.env.example local/.env
	docker compose --env-file local/.env -f local/docker-compose.yml up -d --wait

local-down: ## Stop the local PostgreSQL and discard its data
	docker compose --env-file local/.env -f local/docker-compose.yml down -v

local-invoke: ## Run the real handler once against the database in local/.env
	@test -f local/.env || { echo "missing local/.env: run make local-up first"; exit 1; }
	set -a && . local/.env && set +a && cd $(FUNCTION_DIR) && uv run python scripts/invoke_local.py

build: ## Package the Lambda function into build/ (locked, hash-verified, linux arm64)
	rm -rf build
	mkdir -p $(BUILD_DIR)
	cd $(FUNCTION_DIR) && uv export --frozen --no-dev --no-emit-project -o $(CURDIR)/build/requirements.txt
	uv pip install --quiet --target $(BUILD_DIR) --python-platform aarch64-manylinux2014 --python-version 3.13 --require-hashes --no-deps -r build/requirements.txt
	cp -R $(FUNCTION_DIR)/src/info_api $(BUILD_DIR)/
	find $(BUILD_DIR) -name __pycache__ -type d -prune -exec rm -rf {} +

plan: build ## Plan ENV and save the plan to review (needs AWS credentials and make init)
	@test -d $(ENV_DIR) || { echo "unknown ENV '$(ENV)': $(ENV_DIR) does not exist"; exit 1; }
	$(TF) plan -input=false -lock-timeout=60s -var-file=$(TFVARS) -out=$(ENV).tfplan

apply: ## Apply the plan saved by make plan, and nothing else
	@test -f terraform/$(ENV).tfplan || { echo "no saved plan for '$(ENV)': run make plan ENV=$(ENV) and review it first"; exit 1; }
	$(TF) apply -input=false -lock-timeout=60s $(ENV).tfplan

destroy: build ## Destroy ENV. Needs CONFIRM=yes, and Terraform still asks for confirmation
	@test "$(CONFIRM)" = yes || { echo "refusing to destroy '$(ENV)': run make destroy ENV=$(ENV) CONFIRM=yes"; exit 1; }
	$(TF) destroy -lock-timeout=60s -var-file=$(TFVARS)

verify: ## Call the deployed endpoint and print the response
	curl -sS --fail-with-body "$$($(TF) output -raw info_url)" | jq .

logs: ## Tail the Lambda's CloudWatch logs (needs the AWS CLI)
	aws logs tail "/aws/lambda/$$($(TF) output -raw lambda_function_name)" --since 15m --follow

check: fmt-check validate lint actionlint scan test function-lint function-test ## Everything that needs no database or AWS account
