# Design Document

## Overview

This design extends the existing `confluent-env-export` utility (invoked by `make setup-env`) to support Flink compute pools and TableFlow catalog discovery and API key management. The enhancement follows the established patterns in the codebase for resource discovery, API key creation, and `.env` file generation.

The implementation will add two new resource types to the wizard workflow:
1. **Flink Compute Pools** - Computational resources for Apache Flink SQL queries and streaming applications
2. **TableFlow Catalogs** - Iceberg-based data lakehouse service for querying data in object storage

Both resources will follow the same pattern as existing Kafka and Schema Registry support: discover resources, create API keys, and write configuration to the `.env` file.

## Architecture

### High-Level Flow

```
User runs: make setup-env
    ↓
confluent-env-export script
    ↓
1. Check authentication
2. Select environment
3. Discover Kafka cluster → Create/check API keys
4. Discover Schema Registry → Create/check API keys
5. [NEW] Discover Flink compute pool → Create API keys
6. [NEW] Discover TableFlow → Create API keys
7. Generate .env file with all configurations
```

### Component Structure

The implementation will add new functions to `bin/confluent-env-export`:

```
bin/confluent-env-export
├── discover_flink_compute_pool()      # List and select Flink compute pools
├── create_flink_api_key()             # Create API key for Flink
├── discover_tableflow()               # Discover TableFlow availability
├── create_tableflow_api_key()         # Create API key for TableFlow
├── generate_tableflow_catalog_url()   # Build TableFlow REST catalog URL
└── generate_env_file()                # Updated to include Flink/TableFlow vars
```

## Components and Interfaces

### 1. Flink Compute Pool Discovery

**Function**: `discover_flink_compute_pool()`

**Purpose**: Discover available Flink compute pools in the selected environment

**CLI Command**:
```bash
confluent flink compute-pool list -o json
```

**Expected JSON Output Structure**:
```json
[
  {
    "id": "lfcp-abc123",
    "name": "main-compute-pool",
    "region": "us-east-1",
    "cloud": "aws",
    "max_cfu": 10,
    "status": "RUNNING"
  }
]
```

**Logic**:
- If no compute pools exist: Log info message and skip Flink configuration
- If one compute pool exists: Auto-select it
- If multiple compute pools exist: Present selection menu to user
- Store: `FLINK_COMPUTE_POOL_ID`, `FLINK_COMPUTE_POOL_NAME`, `FLINK_REGION`, `FLINK_CLOUD`

**Error Handling**:
- CLI command failure: Log warning and continue without Flink
- Empty result: Log info and continue
- JSON parsing error: Log error and continue

### 2. Flink API Key Creation

**Function**: `create_flink_api_key()`

**Purpose**: Create a new API key for the selected Flink compute pool

**CLI Command**:
```bash
confluent api-key create --resource "$FLINK_COMPUTE_POOL_ID" \
  --description "Created by confluent-env-export on $(date) for $FLINK_COMPUTE_POOL_NAME"
```

**Expected Output Format** (table format):
```
+------------+------------------+
| API Key    | ABCDEFGHIJ123456 |
| API Secret | xyz...secret...  |
+------------+------------------+
```

**Parsing Strategy**:
```bash
FLINK_API_KEY=$(echo "$key_output" | grep "| API Key" | awk -F'|' '{print $3}' | tr -d ' ')
FLINK_API_SECRET=$(echo "$key_output" | grep "| API Secret" | awk -F'|' '{print $3}' | tr -d ' ')
```

**User Interaction**:
- If `--create-keys` flag: Create automatically without prompting
- Otherwise: Prompt user with `confirm "Create Flink API key?"`
- If user declines: Skip Flink configuration

**Dry Run Behavior**:
- Set placeholder values: `FLINK_API_KEY="DRY-RUN-FLINK-KEY"`
- Log what would be created

### 3. TableFlow Discovery

**Function**: `discover_tableflow()`

**Purpose**: Discover TableFlow availability and extract organization ID

**CLI Commands**:
```bash
# Get organization ID from environment
confluent environment describe "$SELECTED_ENV_ID" -o json

# Alternative: Get from current context
confluent context describe -o json
```

**Expected JSON Structure**:
```json
{
  "id": "env-123abc",
  "name": "production",
  "organization_id": "org-xyz789",
  "stream_governance_package": "ESSENTIALS"
}
```

**Logic**:
- Extract `organization_id` from environment metadata
- Check if TableFlow is available (may require specific governance package)
- Generate catalog URL using: `https://tableflow.${region}.aws.confluent.cloud/iceberg/catalog/organizations/${org_id}/environments/${env_id}`
- Store: `TF_ORG_ID`, `TF_CATALOG_URL`

**Skip Conditions**:
- `--skip-tableflow` flag provided
- Organization ID not available
- TableFlow not enabled for environment

### 4. TableFlow API Key Creation

**Function**: `create_tableflow_api_key()`

**Purpose**: Create API key for TableFlow catalog access

**CLI Command**:
```bash
# TableFlow uses environment-scoped API keys
confluent api-key create --resource "$SELECTED_ENV_ID" \
  --description "Created by confluent-env-export on $(date) for TableFlow"
```

**Note**: TableFlow API keys are typically environment-scoped, not resource-specific. The exact resource type will be validated during implementation.

**Parsing Strategy**: Same as Flink (parse table output)

**User Interaction**: Same pattern as Flink

### 5. Environment File Generation

**Function**: `generate_env_file()` (modified)

**New Environment Variables**:

```bash
# Flink Configuration (when available)
export CC_FLINK_COMPUTE_POOL=lfcp-abc123
export CC_FLINK_REGION=us-east-1
export CC_FLINK_CLOUD=aws
export CC_FLINK_API_KEY=ABCDEFGHIJ123456
export CC_FLINK_API_SECRET=xyz...secret...

# TableFlow Configuration (when available)
export CC_TF_API_KEY=TABLEFLOW_KEY_123
export CC_TF_API_SECRET=tableflow_secret_xyz
export CC_TF_CATALOG_URL=https://tableflow.us-east-1.aws.confluent.cloud/iceberg/catalog/organizations/org-xyz789/environments/env-123abc
export CC_ORG_ID=org-xyz789

# Legacy format for backward compatibility
export CONFLUENT_FLINK_COMPUTE_POOL=$CC_FLINK_COMPUTE_POOL
export CONFLUENT_FLINK_API_KEY=$CC_FLINK_API_KEY
export CONFLUENT_FLINK_API_SECRET=$CC_FLINK_API_SECRET
export CONFLUENT_TABLEFLOW_API_KEY=$CC_TF_API_KEY
export CONFLUENT_TABLEFLOW_API_SECRET=$CC_TF_API_SECRET
export CONFLUENT_TABLEFLOW_CATALOG_URL=$CC_TF_CATALOG_URL
```

**File Structure**:
1. Header comment with generation timestamp
2. Environment information
3. Kafka configuration
4. Schema Registry configuration (if available)
5. **[NEW]** Flink configuration (if available)
6. **[NEW]** TableFlow configuration (if available)
7. Cloud API credentials (if available)
8. Legacy format mappings
9. Optional configuration comments

### 6. Command-Line Flags

**New Flags**:

```bash
--skip-flink          # Skip Flink compute pool discovery and configuration
--skip-tableflow      # Skip TableFlow discovery and configuration
```

**Existing Flags** (behavior extended):

```bash
--create-keys         # Now also creates Flink and TableFlow API keys automatically
--dry-run            # Now also simulates Flink and TableFlow key creation
```

**Updated Usage Function**:
```bash
${YELLOW}Options:${RESET}
  -e, --env-file FILE         Output .env file path (default: .env)
  -f, --force                 Overwrite existing .env file
  -q, --quiet                 Suppress non-essential output
  -v, --verbose               Increase output verbosity
  -n, --dry-run              Show what would be generated without creating files
  --create-keys              Automatically create missing API keys (Kafka, SR, Flink, TableFlow)
  --skip-sr                  Skip Schema Registry setup
  --skip-flink               Skip Flink compute pool setup
  --skip-tableflow           Skip TableFlow setup
  -h, --help                 Show this help message
```

## Data Models

### Flink Compute Pool

```bash
FLINK_COMPUTE_POOL_ID="lfcp-abc123"        # Unique identifier
FLINK_COMPUTE_POOL_NAME="main-pool"        # Human-readable name
FLINK_REGION="us-east-1"                   # Cloud region
FLINK_CLOUD="aws"                          # Cloud provider
FLINK_API_KEY="ABCDEFGHIJ123456"          # API key
FLINK_API_SECRET="xyz...secret..."         # API secret
```

### TableFlow Configuration

```bash
TF_ORG_ID="org-xyz789"                     # Organization ID
TF_CATALOG_URL="https://tableflow..."      # REST catalog endpoint
TF_API_KEY="TABLEFLOW_KEY_123"            # API key
TF_API_SECRET="tableflow_secret_xyz"       # API secret
```

## Error Handling

### Graceful Degradation

The implementation follows the existing pattern of graceful degradation:

1. **Resource Not Available**: Log informational message and continue
2. **CLI Command Failure**: Log warning and skip that resource type
3. **User Declines Key Creation**: Skip that resource type
4. **Parsing Errors**: Log error and continue with other resources

### Error Messages

```bash
# Flink not available
info "No Flink compute pools found in this environment"

# TableFlow not available
info "TableFlow not available in this environment"

# API key creation failed
warning "Failed to create Flink API key"

# CLI command failed
error "Failed to list Flink compute pools"
```

### Validation

- Validate JSON output from CLI commands before parsing
- Check for empty results before processing
- Verify API key/secret were successfully parsed
- Confirm organization ID exists before generating TableFlow URL

## Testing Strategy

### Unit Testing Approach

1. **Mock CLI Responses**: Create test fixtures with sample JSON outputs
2. **Test Each Function**: Isolate and test discovery and creation functions
3. **Test Error Paths**: Verify graceful handling of failures
4. **Test Flag Combinations**: Verify skip flags work correctly

### Integration Testing

1. **Dry Run Mode**: Test complete workflow without creating resources
2. **Manual Testing**: Run against real Confluent Cloud environment
3. **Validation**: Verify generated `.env` file contains correct variables

### Test Scenarios

```bash
# Test 1: Environment with all resources
- Kafka cluster ✓
- Schema Registry ✓
- Flink compute pool ✓
- TableFlow ✓

# Test 2: Environment without Flink
- Kafka cluster ✓
- Schema Registry ✓
- Flink compute pool ✗
- TableFlow ✓

# Test 3: Skip flags
--skip-flink --skip-tableflow

# Test 4: Dry run
--dry-run --create-keys

# Test 5: User declines key creation
Interactive prompts → "no"
```

## Integration with Existing Code

### Shared Libraries

The implementation will use existing shared libraries:

```bash
source "$LIB_DIR/common.sh"      # Logging, colors, emojis
source "$LIB_DIR/config.sh"      # Config generation (already has TableFlow support)
source "$LIB_DIR/validation.sh"  # Input validation
source "$LIB_DIR/output.sh"      # Formatted output
```

### Existing Functions to Reuse

- `confirm()` - User confirmation prompts
- `is_dry_run()` - Check dry run mode
- `progress()`, `success()`, `warning()`, `error()` - Logging
- `header()` - Section headers

### Makefile Integration

No changes required to `Makefile`. The `setup-env` target already calls `confluent-env-export`:

```makefile
setup-env: ## ⚙️ Interactive environment setup and .env generation
> @echo -e "$(BLUE)$(GEAR) Environment Setup$(RESET)"
> @if [ -f "$(BIN_DIR)/confluent-env-export" ]; then \
>   $(BIN_DIR)/confluent-env-export; \
> fi
```

### lib/config.sh Integration

The `lib/config.sh` already has TableFlow support:
- `validate_tableflow_env()` - Validates TableFlow environment variables
- `generate_tableflow_catalog_url()` - Generates catalog URL
- `generate_tableflow_properties()` - Generates properties file

These functions will be leveraged by the new implementation.

## Implementation Notes

### Confluent CLI Version Compatibility

- Minimum CLI version: 3.0.0 (for Flink support)
- TableFlow support: Verify availability in CLI version
- Use `confluent version` to check compatibility

### Cloud Provider Support

Flink and TableFlow are available on:
- AWS ✓
- GCP ✓
- Azure ✓

Region-specific URLs will be generated based on `FLINK_REGION` and cloud provider.

### API Key Scoping

- **Kafka**: Cluster-scoped (`--resource <cluster-id>`)
- **Schema Registry**: Cluster-scoped (`--resource <sr-cluster-id>`)
- **Flink**: Compute pool-scoped (`--resource <compute-pool-id>`)
- **TableFlow**: Environment-scoped or organization-scoped (to be validated)

### Output Formatting

Maintain consistency with existing output:
- Use emojis for visual clarity (🔍 for discovery, 🔑 for keys, ✅ for success)
- Color-code messages (blue for info, green for success, yellow for warnings)
- Show progress indicators for long-running operations
- Display summary at the end

## Security Considerations

### API Secret Handling

- API secrets are only available during key creation
- Secrets are written to `.env` file (which is gitignored)
- User is warned about secret sensitivity
- Dry run mode uses placeholder values

### File Permissions

The generated `.env` file should have restricted permissions:
```bash
chmod 600 "$env_file"  # Read/write for owner only
```

This should be added to `generate_env_file()` function.

## Future Enhancements

### Potential Improvements

1. **Multi-Compute Pool Support**: Allow configuring multiple Flink compute pools
2. **Key Rotation**: Integrate with existing `cc-key-rotate` utility
3. **Validation Commands**: Add `make validate-flink` and `make validate-tableflow`
4. **Property File Generation**: Auto-generate Flink SQL properties
5. **Interactive Testing**: Test connectivity after key creation

### Backward Compatibility

All changes maintain backward compatibility:
- Existing `.env` files remain valid
- New variables are additive
- Skip flags allow disabling new features
- Legacy variable names are supported

## Dependencies

### Required Tools

- `confluent` CLI (version 3.0.0+)
- `jq` for JSON parsing
- `bash` 4.0+

### Optional Tools

- `yq` for YAML output (future enhancement)

## Rollout Plan

### Phase 1: Core Implementation
1. Add Flink discovery and API key creation
2. Add TableFlow discovery and API key creation
3. Update `.env` file generation
4. Add command-line flags

### Phase 2: Testing
1. Unit tests with mocked CLI responses
2. Integration tests with dry-run mode
3. Manual testing with real environments

### Phase 3: Documentation
1. Update README with new features
2. Add examples to documentation
3. Update help text and usage examples

### Phase 4: Validation Tools
1. Add `make validate-flink` target
2. Add `make validate-tableflow` target
3. Update `make validate-all` to include new resources
