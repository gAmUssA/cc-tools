# Confluent Cloud API Key Management Utilities - Makefile
# Following GNU Make 4.0+ best practices with Davis-Hansson patterns

SHELL := bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
.RECIPEPREFIX = >

# GNU Make 4.0+ version check
ifeq ($(origin .RECIPEPREFIX), undefined)
$(error This Make does not support .RECIPEPREFIX. Please use GNU Make 4.0 or later)
endif

# Color definitions
RED := \033[31m
GREEN := \033[32m
YELLOW := \033[33m
BLUE := \033[34m
MAGENTA := \033[35m
CYAN := \033[36m
WHITE := \033[37m
RESET := \033[0m

# Emoji definitions
CHECK := ✅
ROCKET := 🚀
GEAR := ⚙️
WARNING := ⚠️
ERROR := ❌
CLEAN := 🧹
INFO := ℹ️
KEY := 🔑
CLOUD := ☁️
LOCK := 🔐
SYNC := 🔄
HEALTH := 💚
AUDIT := 🔍
BACKUP := 💾
TEST := 🧪
PACKAGE := 📦
VALIDATE := 🔍
SUCCESS := ✅
TABLEFLOW := 🏔️
SEARCH := 🔍

# Project directories
BIN_DIR := bin
LIB_DIR := lib
TEMPLATES_DIR := templates
TESTS_DIR := tests
BUILD_DIR := build
TMP_DIR := tmp
OUT_DIR := out

# Installation directories
PREFIX := /usr/local
INSTALL_BIN_DIR := $(PREFIX)/bin
INSTALL_LIB_DIR := $(PREFIX)/lib/cc-tools
INSTALL_TEMPLATES_DIR := $(PREFIX)/share/cc-tools/templates

# Utilities to install
UTILITIES := cc-key-create cc-key-rotate cc-key-audit cc-key-health cc-config-generate cc-property-files cc-kafka-validate cc-sr-validate cc-tableflow-key-create cc-tableflow-properties confluent-env-export

# Default target
.DEFAULT_GOAL := help

# Phony targets
.PHONY: help install bootstrap test clean audit rotate-all health-check backup status build
.PHONY: validate-flink validate-tableflow validate-all validate-kafka validate-sr
.PHONY: list-keys list-kafka list-sr list-flink list-tableflow
.PHONY: generate-props generate-configs setup-env setup-env-auto create-key

# Help target with colorized output
help: ## ⚙️ Show this help message
> @echo -e "$(BLUE)$(ROCKET) Confluent Cloud API Key Management Utilities$(RESET)"
> @echo -e "$(BLUE)================================================$(RESET)"
> @echo
> @echo -e "$(YELLOW)Available targets:$(RESET)"
> @echo
> @grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(CYAN)%-15s$(RESET)	%s\n", $$1,$$2}'
> @echo
> @echo -e "$(YELLOW)Environment:$(RESET)"
> @echo -e "  $(BLUE)PREFIX$(RESET)         = $(PREFIX)"
> @echo -e "  $(BLUE)INSTALL_BIN_DIR$(RESET) = $(INSTALL_BIN_DIR)"
> @echo

# Status target to show build state
status: ## ℹ️ Show current project status
> @echo -e "$(BLUE)$(INFO) Project Status$(RESET)"
> @echo -e "$(BLUE)===============$(RESET)"
> @echo
> @echo -e "$(YELLOW)Directories:$(RESET)"
> @for dir in $(BIN_DIR) $(LIB_DIR) $(TEMPLATES_DIR) $(TESTS_DIR); do \
>   if [ -d "$$dir" ]; then \
>     echo -e "  $(GREEN)$(CHECK)$(RESET) $$dir"; \
>   else \
>     echo -e "  $(RED)$(ERROR)$(RESET) $$dir (missing)"; \
>   fi; \
> done
> @echo
> @echo -e "$(YELLOW)Shared Libraries:$(RESET)"
> @for lib in common.sh config.sh validation.sh output.sh; do \
>   if [ -f "$(LIB_DIR)/$$lib" ]; then \
>     echo -e "  $(GREEN)$(CHECK)$(RESET) $(LIB_DIR)/$$lib"; \
>   else \
>     echo -e "  $(RED)$(ERROR)$(RESET) $(LIB_DIR)/$$lib (missing)"; \
>   fi; \
> done
> @echo
> @echo -e "$(YELLOW)Utilities:$(RESET)"
> @for util in $(UTILITIES); do \
>   if [ -f "$(BIN_DIR)/$$util" ]; then \
>     echo -e "  $(GREEN)$(CHECK)$(RESET) $(BIN_DIR)/$$util"; \
>   else \
>     echo -e "  $(YELLOW)$(WARNING)$(RESET) $(BIN_DIR)/$$util (not implemented)"; \
>   fi; \
> done

# Bootstrap target for initial setup
bootstrap: ## 🚀 Initial setup and dependency validation
> @echo -e "$(BLUE)$(ROCKET) Bootstrapping Confluent Cloud Tools$(RESET)"
> @echo -e "$(BLUE)========================================$(RESET)"
> @echo
> @echo -e "$(CYAN)$(GEAR) Checking prerequisites...$(RESET)"
> @if ! command -v confluent >/dev/null 2>&1; then \
>   echo -e "$(RED)$(ERROR) confluent CLI not found$(RESET)"; \
>   echo -e "$(YELLOW)$(INFO) Install with: curl -sL --http1.1 https://cnfl.io/cli | sh -s -- latest$(RESET)"; \
>   exit 1; \
> else \
>   echo -e "$(GREEN)$(CHECK) confluent CLI found$(RESET)"; \
> fi
> @if ! confluent auth list 2>/dev/null | grep -q "LOGGED_IN"; then \
>   echo -e "$(YELLOW)$(WARNING) confluent CLI not authenticated$(RESET)"; \
>   echo -e "$(YELLOW)$(INFO) Run 'confluent login --save' to authenticate$(RESET)"; \
> else \
>   echo -e "$(GREEN)$(CHECK) confluent CLI authenticated$(RESET)"; \
> fi
> @echo
> @echo -e "$(CYAN)$(GEAR) Checking optional tools...$(RESET)"
> @for tool in jq yq curl bc; do \
>   if command -v $$tool >/dev/null 2>&1; then \
>     echo -e "$(GREEN)$(CHECK) $$tool available$(RESET)"; \
>   else \
>     echo -e "$(YELLOW)$(WARNING) $$tool not found (recommended)$(RESET)"; \
>   fi; \
> done
> @echo
> @echo -e "$(CYAN)$(GEAR) Setting up environment configuration...$(RESET)"
> @if [ -f ".env" ]; then \
>   echo -e "$(GREEN)$(CHECK) .env file found$(RESET)"; \
> else \
>   echo -e "$(YELLOW)$(WARNING) .env file not found$(RESET)"; \
>   if [ -f ".env.example" ]; then \
>     echo -e "$(CYAN)$(GEAR) Creating .env from .env.example...$(RESET)"; \
>     cp .env.example .env; \
>     echo -e "$(GREEN)$(CHECK) .env file created from template$(RESET)"; \
>     echo -e "$(YELLOW)$(INFO) Please edit .env and configure your actual credentials$(RESET)"; \
>   else \
>     echo -e "$(RED)$(ERROR) .env.example template not found$(RESET)"; \
>     exit 1; \
>   fi; \
> fi
> @echo
> @echo -e "$(CYAN)$(GEAR) Creating required directories...$(RESET)"
> @mkdir -p configs properties backups tmp build out
> @echo -e "$(GREEN)$(CHECK) Directory structure created$(RESET)"
> @echo
> @echo -e "$(GREEN)$(CHECK) Bootstrap completed$(RESET)"
> @echo -e "$(YELLOW)$(INFO) Next steps:$(RESET)"
> @echo -e "$(YELLOW)  1. Edit .env with your Confluent Cloud credentials$(RESET)"
> @echo -e "$(YELLOW)  2. Run 'make validate-all' to test connectivity$(RESET)"
> @echo -e "$(YELLOW)  3. Use 'make help' to see available commands$(RESET)"

# Build target (placeholder for future compilation needs)
build: ## ⚙️ Build all utilities and dependencies
> @echo -e "$(BLUE)$(GEAR) Building utilities$(RESET)"
> @mkdir -p $(BUILD_DIR) $(TMP_DIR)
> @echo -e "$(GREEN)$(CHECK) Build directories created$(RESET)"
> @echo -e "$(YELLOW)$(INFO) No compilation needed for shell scripts$(RESET)"

# Test target for comprehensive test execution
test: ## 🧪 Run unit and integration test suite
> @echo -e "$(BLUE)$(TEST) Running test suite$(RESET)"
> @echo -e "$(BLUE)==================$(RESET)"
> @if [ ! -d "$(TESTS_DIR)" ]; then \
>   echo -e "$(YELLOW)$(WARNING) Tests directory not found$(RESET)"; \
>   exit 0; \
> fi
> @if [ -f "$(TESTS_DIR)/run-all-tests.sh" ]; then \
>   echo -e "$(CYAN)$(GEAR) Executing test runner...$(RESET)"; \
>   bash "$(TESTS_DIR)/run-all-tests.sh"; \
> else \
>   echo -e "$(YELLOW)$(WARNING) Test runner not found$(RESET)"; \
>   echo -e "$(YELLOW)$(INFO) Individual test files:$(RESET)"; \
>   find $(TESTS_DIR) -name "*.sh" -type f | while read test_file; do \
>     echo -e "  $(BLUE)$(INFO)$(RESET) $$test_file"; \
>   done; \
> fi

# Install target for system PATH installation
install: build ## 📦 Install utilities to system PATH
> @echo -e "$(BLUE)$(PACKAGE) Installing Confluent Cloud Tools$(RESET)"
> @echo -e "$(BLUE)====================================$(RESET)"
> @echo
> @echo -e "$(CYAN)$(GEAR) Creating installation directories...$(RESET)"
> @mkdir -p $(INSTALL_BIN_DIR) $(INSTALL_LIB_DIR) $(INSTALL_TEMPLATES_DIR)
> @echo -e "$(GREEN)$(CHECK) Installation directories created$(RESET)"
> @echo
> @echo -e "$(CYAN)$(GEAR) Installing shared libraries...$(RESET)"
> @if [ -d "$(LIB_DIR)" ]; then \
>   cp -r $(LIB_DIR)/* $(INSTALL_LIB_DIR)/; \
>   chmod 644 $(INSTALL_LIB_DIR)/*.sh; \
>   echo -e "$(GREEN)$(CHECK) Shared libraries installed$(RESET)"; \
> else \
>   echo -e "$(RED)$(ERROR) Library directory not found$(RESET)"; \
>   exit 1; \
> fi
> @echo
> @echo -e "$(CYAN)$(GEAR) Installing templates...$(RESET)"
> @if [ -d "$(TEMPLATES_DIR)" ]; then \
>   cp -r $(TEMPLATES_DIR)/* $(INSTALL_TEMPLATES_DIR)/ 2>/dev/null || true; \
>   echo -e "$(GREEN)$(CHECK) Templates installed$(RESET)"; \
> else \
>   echo -e "$(YELLOW)$(WARNING) Templates directory not found$(RESET)"; \
> fi
> @echo
> @echo -e "$(CYAN)$(GEAR) Installing utilities...$(RESET)"
> @installed_count=0; \
> for util in $(UTILITIES); do \
>   if [ -f "$(BIN_DIR)/$$util" ]; then \
>     cp "$(BIN_DIR)/$$util" "$(INSTALL_BIN_DIR)/"; \
>     chmod 755 "$(INSTALL_BIN_DIR)/$$util"; \
>     echo -e "$(GREEN)$(CHECK) $$util installed$(RESET)"; \
>     installed_count=$$((installed_count + 1)); \
>   else \
>     echo -e "$(YELLOW)$(WARNING) $$util not found, skipping$(RESET)"; \
>   fi; \
> done; \
> echo; \
> echo -e "$(GREEN)$(CHECK) Installation completed ($$installed_count utilities installed)$(RESET)"

# List keys target for inventory management
list-keys: ## 🔑 List all API keys with filtering options
> @echo -e "$(BLUE)$(KEY) API Key Inventory$(RESET)"
> @echo -e "$(BLUE)==================$(RESET)"
> @if [ -f "$(BIN_DIR)/cc-key-list" ]; then \
>   $(BIN_DIR)/cc-key-list; \
> else \
>   echo -e "$(RED)$(ERROR) cc-key-list utility not found$(RESET)"; \
>   exit 1; \
> fi

# List Kafka keys only
list-kafka: ## 🔑 List Kafka cluster API keys only
> @echo -e "$(BLUE)$(KEY) Kafka API Keys$(RESET)"
> @echo -e "$(BLUE)=================$(RESET)"
> @if [ -f "$(BIN_DIR)/cc-key-list" ]; then \
>   $(BIN_DIR)/cc-key-list -r kafka; \
> else \
>   echo -e "$(RED)$(ERROR) cc-key-list utility not found$(RESET)"; \
>   exit 1; \
> fi

# List Schema Registry keys only
list-sr: ## 🔑 List Schema Registry API keys only
> @echo -e "$(BLUE)$(KEY) Schema Registry API Keys$(RESET)"
> @echo -e "$(BLUE)===========================$(RESET)"
> @if [ -f "$(BIN_DIR)/cc-key-list" ]; then \
>   $(BIN_DIR)/cc-key-list -r schema-registry; \
> else \
>   echo -e "$(RED)$(ERROR) cc-key-list utility not found$(RESET)"; \
>   exit 1; \
> fi

# List Flink keys only
list-flink: ## 🔑 List Flink region API keys only
> @echo -e "$(BLUE)$(KEY) Flink Region API Keys$(RESET)"
> @echo -e "$(BLUE)======================$(RESET)"
> @if [ -f "$(BIN_DIR)/cc-key-list" ]; then \
>   $(BIN_DIR)/cc-key-list -r flink-region; \
> else \
>   echo -e "$(RED)$(ERROR) cc-key-list utility not found$(RESET)"; \
>   exit 1; \
> fi

# List TableFlow keys only
list-tableflow: ## 🔑 List TableFlow API keys only
> @echo -e "$(BLUE)$(KEY) TableFlow API Keys$(RESET)"
> @echo -e "$(BLUE)==================$(RESET)"
> @if [ -f "$(BIN_DIR)/cc-key-list" ]; then \
>   $(BIN_DIR)/cc-key-list -r tableflow; \
> else \
>   echo -e "$(RED)$(ERROR) cc-key-list utility not found$(RESET)"; \
>   exit 1; \
> fi

# Audit target for comprehensive key audit
audit: ## 🔍 Run comprehensive API key audit
> @echo -e "$(BLUE)$(AUDIT) Running API Key Audit$(RESET)"
> @echo -e "$(BLUE)========================$(RESET)"
> @if [ -f "$(BIN_DIR)/cc-key-audit" ]; then \
>   $(BIN_DIR)/cc-key-audit; \
> else \
>   echo -e "$(YELLOW)$(WARNING) cc-key-audit utility not implemented yet$(RESET)"; \
> fi

# Rotate-all target for bulk key rotation
rotate-all: ## 🔄 Rotate all API keys with confirmation
> @echo -e "$(BLUE)$(SYNC) Bulk API Key Rotation$(RESET)"
> @echo -e "$(BLUE)========================$(RESET)"
> @echo -e "$(RED)$(WARNING) This will rotate ALL API keys!$(RESET)"
> @read -p "Are you sure you want to continue? [y/N]: " confirm; \
> if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
>   if [ -f "$(BIN_DIR)/cc-key-rotate" ]; then \
>     $(BIN_DIR)/cc-key-rotate --all; \
>   else \
>     echo -e "$(YELLOW)$(WARNING) cc-key-rotate utility not implemented yet$(RESET)"; \
>   fi; \
> else \
>   echo -e "$(YELLOW)$(INFO) Operation cancelled$(RESET)"; \
> fi

# Health-check target for validation
health-check: ## 💚 Validate all keys and connectivity
> @echo -e "$(BLUE)$(HEALTH) Health Check$(RESET)"
> @echo -e "$(BLUE)============$(RESET)"
> @if [ -f "$(BIN_DIR)/cc-key-health" ]; then \
>   $(BIN_DIR)/cc-key-health; \
> else \
>   echo -e "$(YELLOW)$(WARNING) cc-key-health utility not implemented yet$(RESET)"; \
>   echo -e "$(CYAN)$(GEAR) Running basic validation...$(RESET)"; \
>   if [ -f "$(LIB_DIR)/validation.sh" ]; then \
>     source $(LIB_DIR)/validation.sh && check_prerequisites; \
>   fi; \
> fi

# Backup target for configuration backup
backup: ## 💾 Backup all key configurations
> @echo -e "$(BLUE)$(BACKUP) Configuration Backup$(RESET)"
> @echo -e "$(BLUE)=====================$(RESET)"
> @backup_dir="backups/$(shell date +%Y%m%d_%H%M%S)"; \
> mkdir -p "$$backup_dir"; \
> echo -e "$(CYAN)$(GEAR) Creating backup in $$backup_dir...$(RESET)"; \
> if [ -f ".env" ]; then \
>   cp ".env" "$$backup_dir/env.backup"; \
>   echo -e "$(GREEN)$(CHECK) Environment configuration backed up$(RESET)"; \
> fi; \
> if [ -d "$(BUILD_DIR)" ]; then \
>   cp -r "$(BUILD_DIR)" "$$backup_dir/"; \
>   echo -e "$(GREEN)$(CHECK) Build artifacts backed up$(RESET)"; \
> fi; \
> echo -e "$(GREEN)$(CHECK) Backup completed: $$backup_dir$(RESET)"

# Generate properties target
generate-props: ## ⚙️ Generate all Kafka property files
> @echo -e "$(BLUE)$(GEAR) Generating Property Files$(RESET)"
> @echo -e "$(BLUE)==========================$(RESET)"
> @if [ -f "$(BIN_DIR)/cc-property-files" ]; then \
>   $(BIN_DIR)/cc-property-files --all; \
> else \
>   echo -e "$(RED)$(ERROR) cc-property-files utility not found$(RESET)"; \
>   exit 1; \
> fi

# Generate configs target
generate-configs: ## ⚙️ Generate client configuration files
> @echo -e "$(BLUE)$(GEAR) Generating Configuration Files$(RESET)"
> @echo -e "$(BLUE)==============================$(RESET)"
> @if [ -f "$(BIN_DIR)/cc-config-generate" ]; then \
>   $(BIN_DIR)/cc-config-generate -c all; \
> else \
>   echo -e "$(RED)$(ERROR) cc-config-generate utility not found$(RESET)"; \
>   exit 1; \
> fi

# Create API key target
create-key: ## 🔑 Create new API key interactively
> @echo -e "$(BLUE)$(KEY) Creating API Key$(RESET)"
> @echo -e "$(BLUE)==================$(RESET)"
> @if [ -f "$(BIN_DIR)/cc-key-create" ]; then \
>   $(BIN_DIR)/cc-key-create; \
> else \
>   echo -e "$(RED)$(ERROR) cc-key-create utility not found$(RESET)"; \
>   exit 1; \
> fi

# Environment setup target
setup-env: ## ⚙️ Interactive environment setup and .env generation
> @echo -e "$(BLUE)$(GEAR) Environment Setup$(RESET)"
> @echo -e "$(BLUE)==================$(RESET)"
> @if [ -f "$(BIN_DIR)/confluent-env-export" ]; then \
>   $(BIN_DIR)/confluent-env-export; \
> else \
>   echo -e "$(RED)$(ERROR) confluent-env-export utility not found$(RESET)"; \
>   exit 1; \
> fi

# Quick environment setup with key creation
setup-env-auto: ## 🚀 Automated environment setup with key creation
> @echo -e "$(BLUE)$(ROCKET) Automated Environment Setup$(RESET)"
> @echo -e "$(BLUE)==============================$(RESET)"
> @if [ -f "$(BIN_DIR)/confluent-env-export" ]; then \
>   $(BIN_DIR)/confluent-env-export --create-keys --force; \
> else \
>   echo -e "$(RED)$(ERROR) confluent-env-export utility not found$(RESET)"; \
>   exit 1; \
> fi

# Generate TableFlow properties target
generate-tableflow-props: ## 🏔️ Generate TableFlow properties file
> @echo -e "$(BLUE)$(TABLEFLOW) Generating TableFlow Properties$(RESET)"
> @echo -e "$(BLUE)=================================$(RESET)"
> @if [ -f "$(BIN_DIR)/cc-tableflow-properties" ]; then \
>   $(BIN_DIR)/cc-tableflow-properties; \
> else \
>   echo -e "$(RED)$(ERROR) cc-tableflow-properties utility not found$(RESET)"; \
>   exit 1; \
> fi

# Validate TableFlow target
validate-tableflow: ## 🏔️ Validate TableFlow connectivity
> @echo -e "$(BLUE)$(VALIDATE) Validating TableFlow connectivity$(RESET)"
> @if [ -f ".env" ]; then \
>   source .env; \
>   if [ -n "$${CC_TF_CATALOG_URL:-}" ] && [ -n "$${CC_TF_API_KEY:-}" ]; then \
>     echo -e "$(CYAN)$(GEAR) TableFlow Catalog URL: $${CC_TF_CATALOG_URL}$(RESET)"; \
>     echo -e "$(CYAN)$(GEAR) Organization ID: $${CC_ORG_ID}$(RESET)"; \
>     echo -e "$(CYAN)$(GEAR) Testing TableFlow catalog access...$(RESET)"; \
>     if curl -s -u "$${CC_TF_API_KEY}:$${CC_TF_API_SECRET}" "$${CC_TF_CATALOG_URL}/v1/config" >/dev/null 2>&1; then \
>       echo -e "$(GREEN)$(CHECK) TableFlow catalog accessible$(RESET)"; \
>     else \
>       echo -e "$(YELLOW)$(WARNING) Could not access TableFlow catalog$(RESET)"; \
>       echo -e "$(CYAN)$(INFO) This may be expected if TableFlow is not fully configured$(RESET)"; \
>     fi; \
>   else \
>     echo -e "$(YELLOW)$(WARNING) TableFlow not configured in .env file$(RESET)"; \
>     echo -e "$(CYAN)$(INFO) Run 'make setup-env' to configure TableFlow$(RESET)"; \
>   fi; \
> else \
>   echo -e "$(RED)$(ERROR) .env file not found$(RESET)"; \
>   exit 1; \
> fi

validate-sr: ## 🔍 Validate Schema Registry connectivity
> @echo -e "$(BLUE)$(VALIDATE) Validating Schema Registry$(RESET)"
> @if [ -f "$(BIN_DIR)/cc-sr-validate" ]; then \
>   $(BIN_DIR)/cc-sr-validate; \
> else \
>   echo -e "$(RED)$(ERROR) cc-sr-validate utility not found$(RESET)"; \
>   exit 1; \
> fi

validate-sr-ssl: ## 🔒 Validate Schema Registry SSL/TLS certificates
> @echo -e "$(BLUE)$(VALIDATE) Validating Schema Registry SSL/TLS$(RESET)"
> @if [ -f "$(BIN_DIR)/cc-sr-validate" ]; then \
>   $(BIN_DIR)/cc-sr-validate --ssl-verify; \
> else \
>   echo -e "$(RED)$(ERROR) cc-sr-validate utility not found$(RESET)"; \
>   exit 1; \
> fi

# Kafka validation targets
validate-kafka: ## ⚡ Validate Kafka connectivity
> @echo -e "$(BLUE)$(VALIDATE) Validating Kafka connectivity$(RESET)"
> @if [ -f "$(BIN_DIR)/cc-kafka-validate" ]; then \
>   $(BIN_DIR)/cc-kafka-validate; \
> else \
>   echo -e "$(RED)$(ERROR) cc-kafka-validate utility not found$(RESET)"; \
>   exit 1; \
> fi

validate-kafka-full: ## ⚡ Run full Kafka diagnostics
> @echo -e "$(BLUE)$(VALIDATE) Running full Kafka diagnostics$(RESET)"
> @if [ -f "$(BIN_DIR)/cc-kafka-validate" ]; then \
>   $(BIN_DIR)/cc-kafka-validate -d; \
> else \
>   echo -e "$(RED)$(ERROR) cc-kafka-validate utility not found$(RESET)"; \
>   exit 1; \
> fi

validate-kafka-ssl: ## 🔒 Validate Kafka SSL/TLS certificates
> @echo -e "$(BLUE)$(VALIDATE) Validating Kafka SSL/TLS$(RESET)"
> @if [ -f "$(BIN_DIR)/cc-kafka-validate" ]; then \
>   $(BIN_DIR)/cc-kafka-validate --ssl-check; \
> else \
>   echo -e "$(RED)$(ERROR) cc-kafka-validate utility not found$(RESET)"; \
>   exit 1; \
> fi

validate-kafka-network: ## 🌐 Test Kafka network connectivity
> @echo -e "$(BLUE)$(VALIDATE) Testing Kafka network connectivity$(RESET)"
> @if [ -f "$(BIN_DIR)/cc-kafka-validate" ]; then \
>   $(BIN_DIR)/cc-kafka-validate --network-test; \
> else \
>   echo -e "$(RED)$(ERROR) cc-kafka-validate utility not found$(RESET)"; \
>   exit 1; \
> fi

validate-flink: ## 🔍 Validate Flink connectivity
> @echo -e "$(BLUE)$(VALIDATE) Validating Flink connectivity$(RESET)"
> @if [ -f ".env" ]; then \
>   source .env; \
>   if [ -n "$${CC_FLINK_COMPUTE_POOL:-}" ] && [ -n "$${CC_FLINK_API_KEY:-}" ]; then \
>     echo -e "$(CYAN)$(GEAR) Flink Compute Pool: $${CC_FLINK_COMPUTE_POOL}$(RESET)"; \
>     echo -e "$(CYAN)$(GEAR) Region: $${CC_FLINK_REGION}$(RESET)"; \
>     echo -e "$(CYAN)$(GEAR) Cloud: $${CC_FLINK_CLOUD}$(RESET)"; \
>     echo -e "$(CYAN)$(GEAR) Testing Flink CLI access...$(RESET)"; \
>     if confluent flink compute-pool describe "$${CC_FLINK_COMPUTE_POOL}" >/dev/null 2>&1; then \
>       echo -e "$(GREEN)$(CHECK) Flink compute pool accessible$(RESET)"; \
>     else \
>       echo -e "$(YELLOW)$(WARNING) Could not access Flink compute pool$(RESET)"; \
>     fi; \
>   else \
>     echo -e "$(YELLOW)$(WARNING) Flink not configured in .env file$(RESET)"; \
>     echo -e "$(CYAN)$(INFO) Run 'make setup-env' to configure Flink$(RESET)"; \
>   fi; \
> else \
>   echo -e "$(RED)$(ERROR) .env file not found$(RESET)"; \
>   exit 1; \
> fi

validate-all: ## 🔍 Run all connectivity validation tests
> @echo -e "$(BLUE)$(VALIDATE) Running all validation tests$(RESET)"
> @echo -e "$(BLUE)==============================$(RESET)"
> @$(MAKE) validate-kafka
> @echo
> @$(MAKE) validate-sr
> @echo
> @if [ -f ".env" ]; then \
>   source .env; \
>   if [ -n "$${CC_FLINK_COMPUTE_POOL:-}" ]; then \
>     $(MAKE) validate-flink; \
>     echo; \
>   fi; \
>   if [ -n "$${CC_TF_CATALOG_URL:-}" ]; then \
>     $(MAKE) validate-tableflow; \
>     echo; \
>   fi; \
> fi
> @echo -e "$(GREEN)$(SUCCESS) All validation tests completed$(RESET)"

# Clean target for organized cleanup
clean: ## 🧹 Remove all generated files and directories
> @echo -e "$(BLUE)$(CLEAN) Cleaning up$(RESET)"
> @echo -e "$(BLUE)============$(RESET)"
> @echo -e "$(CYAN)$(GEAR) Removing build artifacts...$(RESET)"
> @rm -rf $(BUILD_DIR) $(TMP_DIR) $(OUT_DIR)
> @echo -e "$(GREEN)$(CHECK) Build directories cleaned$(RESET)"
> @echo
> @echo -e "$(CYAN)$(GEAR) Removing generated files...$(RESET)"
> @rm -rf properties/ configs/ backups/
> @echo -e "$(GREEN)$(CHECK) Generated files cleaned$(RESET)"
> @echo
> @echo -e "$(CYAN)$(GEAR) Removing backup files...$(RESET)"
> @find . -name "*.backup" -type f -delete 2>/dev/null || true
> @find . -name "*~" -type f -delete 2>/dev/null || true
> @echo -e "$(GREEN)$(CHECK) Backup files cleaned$(RESET)"
> @echo
> @echo -e "$(GREEN)$(CHECK) Cleanup completed$(RESET)"

# Uninstall target
uninstall: ## ❌ Remove installed utilities from system
> @echo -e "$(BLUE)$(ERROR) Uninstalling Confluent Cloud Tools$(RESET)"
> @echo -e "$(BLUE)=====================================$(RESET)"
> @echo -e "$(CYAN)$(GEAR) Removing installed utilities...$(RESET)"
> @for util in $(UTILITIES); do \
>   if [ -f "$(INSTALL_BIN_DIR)/$$util" ]; then \
>     rm -f "$(INSTALL_BIN_DIR)/$$util"; \
>     echo -e "$(GREEN)$(CHECK) $$util removed$(RESET)"; \
>   fi; \
> done
> @echo -e "$(CYAN)$(GEAR) Removing shared libraries...$(RESET)"
> @rm -rf $(INSTALL_LIB_DIR)
> @echo -e "$(CYAN)$(GEAR) Removing templates...$(RESET)"
> @rm -rf $(INSTALL_TEMPLATES_DIR)
> @echo -e "$(GREEN)$(CHECK) Uninstallation completed$(RESET)"

# Development targets
dev-setup: bootstrap ## ⚙️ Set up development environment
> @echo -e "$(BLUE)$(GEAR) Development Environment Setup$(RESET)"
> @echo -e "$(BLUE)===============================$(RESET)"
> @if ! command -v bats >/dev/null 2>&1; then \
>   echo -e "$(YELLOW)$(WARNING) bats testing framework not found$(RESET)"; \
>   echo -e "$(YELLOW)$(INFO) Install with: npm install -g bats$(RESET)"; \
> else \
>   echo -e "$(GREEN)$(CHECK) bats testing framework available$(RESET)"; \
> fi
> @echo -e "$(GREEN)$(CHECK) Development environment ready$(RESET)"

# Lint target for shell script validation
lint: ## ⚙️ Lint shell scripts
> @echo -e "$(BLUE)$(GEAR) Linting shell scripts$(RESET)"
> @echo -e "$(BLUE)=====================$(RESET)"
> @if command -v shellcheck >/dev/null 2>&1; then \
>   find $(LIB_DIR) $(BIN_DIR) -name "*.sh" -type f | while read script; do \
>     echo -e "$(CYAN)$(GEAR) Checking $$script...$(RESET)"; \
>     shellcheck -x "$$script" && echo -e "$(GREEN)$(CHECK) $$script passed$(RESET)" || echo -e "$(RED)$(ERROR) $$script failed$(RESET)"; \
>   done; \
> else \
>   echo -e "$(YELLOW)$(WARNING) shellcheck not found$(RESET)"; \
>   echo -e "$(YELLOW)$(INFO) Install with: brew install shellcheck$(RESET)"; \
> fi
