# Technology Stack

## Build System

**GNU Make 4.0+** with Davis-Hansson best practices

### Required Makefile Preamble

All Makefiles must include:

```makefile
SHELL := bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
.RECIPEPREFIX = >

ifeq ($(origin .RECIPEPREFIX), undefined)
$(error This Make does not support .RECIPEPREFIX. Please use GNU Make 4.0 or later)
endif
```

## Core Technologies

- **Language**: Bash 4.0+ shell scripts
- **CLI Foundation**: Confluent CLI (`confluent` command)
- **Configuration**: Environment-driven with `.env` files
- **JSON Processing**: `jq` for parsing CLI output
- **Optional Tools**: `yq`, `curl`, `bc`, `shellcheck`

## Common Commands

### Setup & Installation

```bash
make bootstrap          # Initial setup and dependency validation
make install           # Install utilities to system PATH (/usr/local/bin)
make dev-setup         # Set up development environment
```

### Key Management

```bash
make list-keys         # List all API keys
make list-kafka        # List Kafka cluster keys only
make list-sr           # List Schema Registry keys only
make create-key        # Create new API key interactively
make audit             # Run comprehensive key audit
make rotate-all        # Rotate all keys (with confirmation)
make health-check      # Validate all keys and connectivity
```

### Configuration Generation

```bash
make generate-props    # Generate all Kafka property files
make generate-configs  # Generate client configuration files
make setup-env         # Interactive environment setup
make setup-env-auto    # Automated setup with key creation
```

### Validation

```bash
make validate-all      # Run all validation tests
make validate-kafka    # Validate Kafka connectivity
make validate-sr       # Validate Schema Registry connectivity
make test              # Run test suite
```

### Maintenance

```bash
make status            # Show current project status
make backup            # Backup all configurations
make clean             # Remove generated files
make uninstall         # Remove installed utilities
```

## Shared Libraries

Located in `lib/` directory:

- **common.sh**: Color/emoji definitions, logging functions, utility helpers
- **config.sh**: Environment loading, validation, config generation
- **validation.sh**: Input validation, prerequisite checks
- **output.sh**: Formatted output (JSON, CSV, YAML, table)

## Environment Variables

### CC_ Prefix Format (Primary)

- `CC_ENV` - Environment ID
- `CC_ENV_NAME` - Environment name
- `CC_KAFKA_CLUSTER` - Kafka cluster ID
- `CC_KAFKA_BROKER` - Bootstrap servers (without protocol prefix)
- `CC_REGION` - Cloud region
- `CC_CLOUD` - Cloud provider (aws/gcp/azure)
- `CC_KC_API_KEY` / `CC_KC_API_SECRET` - Kafka credentials
- `CC_SR_ID` / `CC_SR_HOST` - Schema Registry info
- `CC_SR_API_KEY` / `CC_SR_API_SECRET` - SR credentials
- `CC_CLOUD_API_KEY` / `CC_CLOUD_API_SECRET` - Cloud-level credentials

### CONFLUENT_ Prefix (Legacy Compatibility)

Mapped from CC_ equivalents for backward compatibility.

## Testing

- **Framework**: `bats` (Bash Automated Testing System)
- **Linting**: `shellcheck` for shell script validation
- **Test Location**: `tests/` directory
