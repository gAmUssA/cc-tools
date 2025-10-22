# Requirements Document

## Introduction

This feature extends the existing `make setup-env` wizard-style command to include Flink and TableFlow resource discovery and API key management. The current implementation supports Kafka clusters, Schema Registry, and Cloud-level API keys. This enhancement will add support for Flink compute pools and TableFlow catalogs, allowing users to generate a complete `.env` file with all necessary credentials for working with these services.

## Glossary

- **Setup Wizard**: The interactive `confluent-env-export` utility invoked by `make setup-env` that guides users through environment configuration
- **Flink Compute Pool**: A Confluent Cloud resource for running Apache Flink SQL queries and streaming applications
- **TableFlow**: Confluent's Iceberg-based data lakehouse service for querying and managing data in object storage
- **API Key**: Authentication credentials (key/secret pair) required to access Confluent Cloud resources
- **Environment File**: The `.env` file containing exported environment variables for Confluent Cloud configuration
- **Resource Discovery**: The process of listing and identifying available Confluent Cloud resources in an environment
- **CC_ Prefix**: The primary environment variable naming convention used in the project (e.g., CC_ENV, CC_KAFKA_CLUSTER)

## Requirements

### Requirement 1

**User Story:** As a developer using Confluent Cloud, I want the setup wizard to discover Flink compute pools in my environment, so that I can automatically configure Flink credentials in my .env file

#### Acceptance Criteria

1. WHEN THE Setup Wizard runs, THE Setup Wizard SHALL discover all Flink compute pools in the selected environment using the Confluent CLI
2. IF multiple Flink compute pools exist, THEN THE Setup Wizard SHALL present a selection menu to the user
3. IF exactly one Flink compute pool exists, THEN THE Setup Wizard SHALL automatically select that compute pool
4. IF no Flink compute pools exist, THEN THE Setup Wizard SHALL log an informational message and continue without Flink configuration
5. WHEN a Flink compute pool is selected, THE Setup Wizard SHALL extract the compute pool ID, name, region, and cloud provider

### Requirement 2

**User Story:** As a developer using Confluent Cloud, I want the setup wizard to create new Flink API keys, so that I can obtain both the key and secret for my configuration

#### Acceptance Criteria

1. WHEN a Flink compute pool is discovered, THE Setup Wizard SHALL create a new API key for that compute pool resource
2. THE Setup Wizard SHALL use the Confluent CLI to create the API key and capture both the key and secret during creation
3. WHERE the `--create-keys` flag is provided, THE Setup Wizard SHALL create the API key without prompting the user
4. WHERE the `--create-keys` flag is not provided, THE Setup Wizard SHALL prompt the user for confirmation before creating the API key
5. IF the user declines to create an API key, THEN THE Setup Wizard SHALL skip Flink configuration and continue with other resources

### Requirement 3

**User Story:** As a developer using Confluent Cloud, I want Flink API key creation to be reliable and informative, so that I can trust the generated credentials

#### Acceptance Criteria

1. WHEN creating a Flink API key, THE Setup Wizard SHALL include a descriptive label containing the script name, timestamp, and compute pool name
2. WHEN the API key creation succeeds, THE Setup Wizard SHALL parse both the API key and API secret from the CLI output
3. IF the API key creation fails, THEN THE Setup Wizard SHALL log an error message and continue without Flink configuration
4. WHERE the `--dry-run` flag is provided, THE Setup Wizard SHALL simulate key creation without making actual API calls
5. THE Setup Wizard SHALL display a success message with the created API key identifier after successful creation

### Requirement 4

**User Story:** As a developer using Confluent Cloud, I want the setup wizard to discover TableFlow catalogs in my environment, so that I can automatically configure TableFlow credentials in my .env file

#### Acceptance Criteria

1. WHEN THE Setup Wizard runs, THE Setup Wizard SHALL discover TableFlow catalog information in the selected environment
2. THE Setup Wizard SHALL extract the organization ID required for TableFlow catalog URL generation
3. THE Setup Wizard SHALL generate the TableFlow catalog REST endpoint URL using the organization ID, environment ID, and region
4. IF TableFlow is not available in the environment, THEN THE Setup Wizard SHALL log an informational message and continue without TableFlow configuration
5. WHERE the `--skip-tableflow` flag is provided, THE Setup Wizard SHALL skip TableFlow discovery entirely

### Requirement 5

**User Story:** As a developer using Confluent Cloud, I want the setup wizard to create TableFlow API keys, so that I can authenticate to the TableFlow catalog service

#### Acceptance Criteria

1. WHEN TableFlow is discovered, THE Setup Wizard SHALL create a new API key for TableFlow access
2. THE Setup Wizard SHALL use the Confluent CLI to create the API key and capture both the key and secret during creation
3. WHERE the `--create-keys` flag is provided, THE Setup Wizard SHALL create the API key without prompting the user
4. WHERE the `--create-keys` flag is not provided, THE Setup Wizard SHALL prompt the user for confirmation before creating the API key
5. IF the user declines to create an API key, THEN THE Setup Wizard SHALL skip TableFlow configuration and continue with other resources

### Requirement 6

**User Story:** As a developer using Confluent Cloud, I want Flink and TableFlow configuration written to my .env file, so that I can use these credentials in my applications and scripts

#### Acceptance Criteria

1. WHEN Flink configuration is available, THE Setup Wizard SHALL write Flink environment variables to the .env file using the CC_ prefix format
2. THE Setup Wizard SHALL include CC_FLINK_COMPUTE_POOL, CC_FLINK_REGION, CC_FLINK_CLOUD, CC_FLINK_API_KEY, and CC_FLINK_API_SECRET variables
3. WHEN TableFlow configuration is available, THE Setup Wizard SHALL write TableFlow environment variables to the .env file using the CC_ prefix format
4. THE Setup Wizard SHALL include CC_TF_API_KEY, CC_TF_API_SECRET, CC_TF_CATALOG_URL, and CC_ORG_ID variables
5. THE Setup Wizard SHALL maintain backward compatibility by including legacy CONFLUENT_ prefix mappings for all new variables

### Requirement 7

**User Story:** As a developer using Confluent Cloud, I want the setup wizard to support command-line flags for Flink and TableFlow, so that I can control the discovery and configuration process

#### Acceptance Criteria

1. THE Setup Wizard SHALL support a `--skip-flink` flag to bypass Flink discovery and configuration
2. THE Setup Wizard SHALL support a `--skip-tableflow` flag to bypass TableFlow discovery and configuration
3. THE Setup Wizard SHALL document these new flags in the usage help text
4. WHEN both skip flags are provided, THE Setup Wizard SHALL only configure Kafka, Schema Registry, and Cloud resources
5. THE Setup Wizard SHALL maintain the existing `--create-keys` flag behavior for all resource types including Flink and TableFlow

### Requirement 8

**User Story:** As a developer using Confluent Cloud, I want the setup wizard to validate Flink and TableFlow configuration, so that I can ensure my credentials are correct

#### Acceptance Criteria

1. WHEN Flink configuration is written to the .env file, THE Setup Wizard SHALL display a summary of the Flink compute pool and API key information
2. WHEN TableFlow configuration is written to the .env file, THE Setup Wizard SHALL display the generated catalog URL and API key information
3. THE Setup Wizard SHALL include Flink and TableFlow in the "Next Steps" guidance shown after successful completion
4. THE Setup Wizard SHALL suggest validation commands for testing Flink and TableFlow connectivity
5. THE Setup Wizard SHALL maintain consistent output formatting with existing resource types using colors and emojis
