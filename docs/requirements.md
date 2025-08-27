# Confluent Cloud API Key Management Utilities - Agentic IDEA Prompt

## 🎯 Project Overview
Create a comprehensive set of command-line utilities for managing Confluent Cloud API keys with enhanced functionality, automation, and developer experience improvements over the standard `confluent api-key` commands.

## 🏗️ Architecture Requirements

### Core Technologies
- **Language**: Shell scripts with Bash 4.0+ compatibility
- **Build System**: GNU Make with emoji-enhanced, colorized output
- **Configuration**: Environment-driven with `.env` as single source of truth
- **CLI Framework**: Leverage existing `confluent` CLI commands as building blocks

### Configuration Management
- **Primary Config**: `.env` file containing all Confluent Cloud connection parameters
- **Derived Configs**: All property files auto-generated from `.env` values
- **Generated Environment Variables (CC_ prefix format)**:
  - `CC_ENV` - Selected environment ID
  - `CC_ENV_NAME` - Environment name
  - `CC_KAFKA_CLUSTER` - Kafka cluster ID
  - `CC_KAFKA_BROKER` - Bootstrap servers (without SASL_SSL:// and https://)
  - `CC_REGION` - Cloud region
  - `CC_CLOUD` - Cloud provider
  - `CC_KC_API_KEY` - Kafka API key
  - `CC_KC_API_SECRET` - Kafka API secret
  - `CC_SR_ID` - Schema Registry cluster ID
  - `CC_SR_HOST` - Schema Registry hostname (without https://)
  - `CC_SR_API_KEY` - Schema Registry API key
  - `CC_SR_API_SECRET` - Schema Registry API secret
  - `CC_CLOUD_API_KEY` - Cloud-level API key
  - `CC_CLOUD_API_SECRET` - Cloud-level API secret

**Legacy Variables (for backward compatibility)**:
  - All `CONFLUENT_*` variables are mapped from `CC_*` equivalents
  - Maintains compatibility with existing utilities and property files

## 🛠️ Utility Commands to Implement

### 1. Enhanced API Key Management
Based on available confluent CLI commands:
- `confluent api-key create` - Create API keys for a given resource
- `confluent api-key delete` - Delete one or more API keys  
- `confluent api-key describe` - Describe an API key
- `confluent api-key list` - List the API keys
- `confluent api-key store` - Store an API key/secret locally
- `confluent api-key update` - Update an API key
- `confluent api-key use` - Use an API key in subsequent commands

### 2. Utility Scripts to Create

#### `cc-key-create` 
- Interactive key creation with resource type selection
- Automatic description generation with timestamp and purpose
- Auto-store newly created keys locally
- Support bulk creation for multiple resources
- Generate configuration files for different client types

#### `cc-key-list`
- List all API keys with detailed information (key, description, resource, age, status)
- Interactive selection for individual key deletion
- Bulk delete functionality with confirmation prompts
- Filter keys by resource type, age, or status
- Export key inventory to multiple formats (JSON, CSV, table)
- Safe deletion with confirmation and dry-run mode

#### `cc-key-rotate`
- Automated key rotation with zero-downtime transition
- Create new key → Update applications → Delete old key workflow
- Integration with CI/CD pipelines
- Rollback capability
- Notification hooks (Slack/email/webhook)

#### `cc-key-audit`
- List all keys with usage metadata (last used, permissions)
- Identify unused/stale keys for cleanup
- Export audit reports (JSON/CSV/HTML)
- Key age analysis and rotation recommendations
- Permission scope analysis

#### `cc-key-sync`
- Sync keys between environments (dev/staging/prod)
- Backup/restore key configurations
- Template-based key provisioning
- Bulk key operations with confirmation prompts

#### `cc-key-health`
- Test key validity and permissions
- Network connectivity checks
- Resource accessibility validation
- Performance benchmarking
- Alert on expiring keys

#### `cc-env-bootstrap`
- Complete environment setup from templates
- Create all necessary service accounts and keys
- Generate client configuration files
- Set up RBAC permissions
- Validate complete setup

### 3. Configuration Generators

#### `cc-config-generate`
Generate client configuration files for:
- **Java**: `application.properties`, `kafka.properties`
- **Python**: `client.properties`, environment configs
- **Node.js**: `.env` files, JSON configs  
- **Go**: YAML/TOML configs
- **Docker**: Environment files
- **Terraform**: Variable files

#### `cc-property-files`
Auto-generate property files from `.env`:
- Producer/Consumer properties
- Connect worker properties
- Schema Registry properties
- Flink SQL properties
- TableFlow properties

#### `confluent-env-export`
Automated environment setup and `.env` generation:
- Interactive environment discovery and selection
- Automatic Kafka cluster detection
- Schema Registry auto-discovery
- Existing API key detection and reuse
- Automatic API key creation when missing
- Complete `.env` file generation with all variables
- Dry-run mode and force overwrite protection
- Multi-environment support with governance package display
- Kafka REST properties

## 🎨 Makefile Requirements

### Enhanced Developer Experience
```makefile
# Use emoji and ANSI colors for better visual feedback
SHELL := /bin/bash
.PHONY: help install test clean bootstrap

# Color definitions
GREEN := \033[32m
BLUE := \033[34m
YELLOW := \033[33m
RED := \033[31m
RESET := \033[0m

# Emoji definitions
CHECK := ✅
ROCKET := 🚀
GEAR := ⚙️
WARNING := ⚠️
ERROR := ❌
CLEAN := 🧹
```

### Key Makefile Targets
- `make install` 📦 - Install all utilities to system PATH
- `make bootstrap` 🚀 - Initial setup: validate deps, create configs
- `make test` 🧪 - Run all validation tests
- `make audit` 🔍 - Run comprehensive key audit
- `make rotate-all` 🔄 - Rotate all keys with confirmation
- `make health-check` 💚 - Validate all keys and connectivity
- `make backup` 💾 - Backup all key configurations
- `make clean` 🧹 - Clean temporary files and caches

## 🔧 Technical Implementation Details

### Prerequisites Validation
```bash
# Each script must validate:
# 1. confluent CLI is installed and logged in
confluent auth list | grep -q "LOGGED_IN" || { echo "❌ Run 'confluent login --save' first"; exit 1; }

# 2. .env file exists and is valid
[[ -f .env ]] || { echo "❌ .env file not found"; exit 1; }

# 3. Required environment variables are set
source .env && [[ -n "$CONFLUENT_ENVIRONMENT_ID" ]] || { echo "❌ CONFLUENT_ENVIRONMENT_ID not set"; exit 1; }
```

### Error Handling Patterns
```bash
# Consistent error reporting with colors and emojis
error() {
    echo -e "${RED}❌ ERROR:${RESET} $1" >&2
}

success() {
    echo -e "${GREEN}✅ SUCCESS:${RESET} $1"
}

warning() {
    echo -e "${YELLOW}⚠️  WARNING:${RESET} $1"
}

info() {
    echo -e "${BLUE}ℹ️  INFO:${RESET} $1"
}
```

### Configuration File Generation
```bash
# Template system for generating configs
generate_java_properties() {
    local output_file="$1"
    cat > "$output_file" << EOF
# Generated from .env on $(date)
bootstrap.servers=${CONFLUENT_BOOTSTRAP_SERVERS}
security.protocol=SASL_SSL
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required \\
    username='${CONFLUENT_CLOUD_API_KEY}' \\
    password='${CONFLUENT_CLOUD_API_SECRET}';
EOF
    success "Generated Java properties: $output_file"
}
```

### Interactive Features
- Colored menu systems using `select` statements
- Progress bars for long operations using `pv` or custom indicators
- Confirmation prompts with colored output
- Tab completion for resource IDs and names
- Help system with examples

### Integration Points
- **CI/CD**: Exit codes, JSON output modes, silent operation flags
- **Monitoring**: Prometheus metrics export, logging to syslog
- **Notifications**: Webhook support, Slack integration
- **Security**: Secure credential handling, audit logging

## 📋 Input/Output Specifications

### Command Line Interface
```bash
# Standard flag patterns
--env-file PATH          # Override default .env location  
--output-format FORMAT   # json|yaml|table|csv
--quiet, -q             # Suppress non-essential output
--verbose, -v           # Increase output verbosity
--dry-run              # Show what would be done without executing
--force                # Skip confirmations
--config-dir PATH      # Override default config directory
```

### Output Formats
- **Human-readable**: Colorized tables with emoji status indicators
- **JSON**: Structured output for programmatic consumption
- **CSV**: For spreadsheet analysis and reporting
- **YAML**: For configuration management tools

### File Structure
```
confluent-utils/
├── Makefile                    # Main build and operation targets
├── .env.example               # Template for environment variables
├── bin/                       # Executable utilities
│   ├── cc-key-create
│   ├── cc-key-rotate  
│   ├── cc-key-audit
│   ├── cc-key-sync
│   ├── cc-key-health
│   ├── cc-env-bootstrap
│   ├── cc-config-generate
│   └── cc-property-files
├── lib/                       # Shared library functions
│   ├── common.sh             # Common functions and variables
│   ├── config.sh             # Configuration management
│   ├── validation.sh         # Input validation functions
│   └── output.sh             # Output formatting functions
├── templates/                 # Configuration templates
│   ├── java.properties.tpl
│   ├── python.env.tpl
│   ├── docker-compose.yml.tpl
│   └── terraform.tfvars.tpl
└── tests/                     # Test scripts
    ├── test-common.sh
    └── run-all-tests.sh
```

## 🧪 Testing Requirements
- Unit tests for individual functions
- Integration tests with actual Confluent Cloud (using test environment)
- Error condition testing
- Configuration validation testing
- Performance testing for bulk operations

## 📚 Documentation Requirements
- Comprehensive README with setup instructions
- Man pages for each utility
- Usage examples and common workflows
- Troubleshooting guide
- Integration examples for popular tools

## 🚀 Advanced Features
- **Bash completion**: Tab completion for all commands and options
- **Configuration validation**: Syntax checking and connectivity testing
- **Template system**: Customizable configuration templates
- **Plugin architecture**: Extensible for custom key management workflows
- **Monitoring integration**: Export metrics for key usage and health
- **Automated rotation schedules**: Cron-compatible rotation scheduling

---

## Implementation Instructions

Create a production-ready set of command-line utilities that:
1. **Enhance** the existing confluent CLI capabilities
2. **Automate** common key management workflows  
3. **Simplify** configuration management across environments
4. **Provide** excellent developer experience with colors, emojis, and clear feedback
5. **Ensure** robust error handling and validation
6. **Support** integration with modern DevOps toolchains

The utilities should feel like a natural extension of the confluent CLI while providing significantly enhanced productivity and automation capabilities for teams managing multiple Confluent Cloud environments and applications.