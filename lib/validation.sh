#!/bin/bash
# lib/validation.sh - Input validation and prerequisite checking functions

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/common.sh"

# Check if confluent CLI is installed and accessible
check_confluent_cli() {
    if ! command_exists confluent; then
        error "confluent CLI is not installed or not in PATH"
        info "Install confluent CLI: curl -sL --http1.1 https://cnfl.io/cli | sh -s -- latest"
        return 1
    fi
    
    debug "confluent CLI found: $(which confluent)"
    return 0
}

# Check if confluent CLI is logged in
check_confluent_auth() {
    # Try multiple methods to check authentication
    
    # Method 1: Check if we can list environments (most reliable)
    if confluent environment list >/dev/null 2>&1; then
        success "confluent CLI is authenticated"
        return 0
    fi
    
    # Method 2: Check auth list command
    if confluent auth list 2>/dev/null | grep -q "LOGGED_IN"; then
        success "confluent CLI is authenticated"
        return 0
    fi
    
    # Method 3: Try to get current user info
    if confluent iam user describe --current >/dev/null 2>&1; then
        success "confluent CLI is authenticated"
        return 0
    fi
    
    error "confluent CLI is not logged in"
    info "Run 'confluent login --save' to authenticate"
    return 1
}

# Validate confluent CLI version
validate_confluent_version() {
    local min_version="${1:-3.0.0}"
    
    if ! check_confluent_cli; then
        return 1
    fi
    
    local current_version
    current_version=$(confluent version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
    
    if [[ -z "$current_version" ]]; then
        warning "Could not determine confluent CLI version"
        return 0  # Continue anyway
    fi
    
    version_compare "$current_version" "$min_version"
    local result=$?
    
    case $result in
        0)
            success "confluent CLI version $current_version meets minimum requirement ($min_version)"
            ;;
        1)
            success "confluent CLI version $current_version exceeds minimum requirement ($min_version)"
            ;;
        2)
            error "confluent CLI version $current_version is below minimum requirement ($min_version)"
            info "Please upgrade confluent CLI to version $min_version or later"
            return 1
            ;;
    esac
    
    return 0
}

# Validate environment ID format
validate_environment_id() {
    local env_id="$1"
    
    if [[ -z "$env_id" ]]; then
        error "Environment ID is empty"
        return 1
    fi
    
    if [[ ! "$env_id" =~ ^env-[a-zA-Z0-9]+$ ]]; then
        error "Invalid environment ID format: $env_id"
        info "Environment ID should match pattern: env-xxxxxx"
        return 1
    fi
    
    debug "Environment ID format is valid: $env_id"
    return 0
}

# Validate cluster ID format
validate_cluster_id() {
    local cluster_id="$1"
    
    if [[ -z "$cluster_id" ]]; then
        error "Cluster ID is empty"
        return 1
    fi
    
    if [[ ! "$cluster_id" =~ ^lkc-[a-zA-Z0-9]+$ ]]; then
        error "Invalid cluster ID format: $cluster_id"
        info "Cluster ID should match pattern: lkc-xxxxxx"
        return 1
    fi
    
    debug "Cluster ID format is valid: $cluster_id"
    return 0
}

# Validate API key format
validate_api_key() {
    local api_key="$1"
    local key_type="${2:-API key}"
    
    if [[ -z "$api_key" ]]; then
        error "$key_type is empty"
        return 1
    fi
    
    # Basic validation - API keys are typically alphanumeric with some special chars
    if [[ ${#api_key} -lt 10 ]]; then
        error "$key_type appears too short: ${#api_key} characters"
        return 1
    fi
    
    debug "$key_type format appears valid"
    return 0
}

# Validate API secret format
validate_api_secret() {
    local api_secret="$1"
    local secret_type="${2:-API secret}"
    
    if [[ -z "$api_secret" ]]; then
        error "$secret_type is empty"
        return 1
    fi
    
    # Basic validation - API secrets are typically longer than keys
    if [[ ${#api_secret} -lt 20 ]]; then
        error "$secret_type appears too short: ${#api_secret} characters"
        return 1
    fi
    
    debug "$secret_type format appears valid"
    return 0
}

# Validate URL format
validate_url() {
    local url="$1"
    local url_type="${2:-URL}"
    
    if [[ -z "$url" ]]; then
        error "$url_type is empty"
        return 1
    fi
    
    if [[ ! "$url" =~ ^https?:// ]]; then
        error "Invalid $url_type format: $url"
        info "$url_type must start with http:// or https://"
        return 1
    fi
    
    debug "$url_type format is valid: $url"
    return 0
}

# Validate cloud provider
validate_cloud_provider() {
    local cloud="$1"
    local valid_clouds=("aws" "gcp" "azure")
    
    if [[ -z "$cloud" ]]; then
        error "Cloud provider is empty"
        return 1
    fi
    
    for valid_cloud in "${valid_clouds[@]}"; do
        if [[ "$cloud" == "$valid_cloud" ]]; then
            debug "Cloud provider is valid: $cloud"
            return 0
        fi
    done
    
    error "Invalid cloud provider: $cloud"
    info "Valid cloud providers: ${valid_clouds[*]}"
    return 1
}

# Test network connectivity to Confluent Cloud
test_connectivity() {
    local bootstrap_servers="$1"
    
    if [[ -z "$bootstrap_servers" ]]; then
        error "Bootstrap servers not specified for connectivity test"
        return 1
    fi
    
    progress "Testing connectivity to $bootstrap_servers"
    
    # Extract hostname and port
    local host_port="${bootstrap_servers%%,*}"  # Get first server
    local host="${host_port%:*}"
    local port="${host_port##*:}"
    
    # Test connectivity using nc (netcat) or telnet
    if command_exists nc; then
        if timeout 10 nc -z "$host" "$port" 2>/dev/null; then
            success "Connectivity test passed for $host:$port"
            return 0
        else
            error "Connectivity test failed for $host:$port"
            return 1
        fi
    elif command_exists telnet; then
        if timeout 10 bash -c "echo '' | telnet $host $port" 2>/dev/null | grep -q "Connected"; then
            success "Connectivity test passed for $host:$port"
            return 0
        else
            error "Connectivity test failed for $host:$port"
            return 1
        fi
    else
        warning "Neither nc nor telnet available for connectivity testing"
        return 0  # Skip test
    fi
}

# Test Schema Registry connectivity
test_schema_registry_connectivity() {
    local sr_url="$1"
    local sr_key="$2"
    local sr_secret="$3"
    
    if [[ -z "$sr_url" ]]; then
        debug "Schema Registry URL not provided, skipping connectivity test"
        return 0
    fi
    
    progress "Testing Schema Registry connectivity"
    
    if command_exists curl; then
        local auth_header=""
        if [[ -n "$sr_key" && -n "$sr_secret" ]]; then
            auth_header="-u $sr_key:$sr_secret"
        fi
        
        if curl -s --max-time 10 "$auth_header" "$sr_url/subjects" >/dev/null 2>&1; then
            success "Schema Registry connectivity test passed"
            return 0
        else
            error "Schema Registry connectivity test failed"
            return 1
        fi
    else
        warning "curl not available for Schema Registry connectivity testing"
        return 0  # Skip test
    fi
}

# Validate file path and permissions
validate_file_path() {
    local file_path="$1"
    local operation="${2:-read}"  # read, write, execute
    
    if [[ -z "$file_path" ]]; then
        error "File path is empty"
        return 1
    fi
    
    case "$operation" in
        read)
            if [[ ! -r "$file_path" ]]; then
                error "File is not readable: $file_path"
                return 1
            fi
            ;;
        write)
            local dir_path
            dir_path=$(dirname "$file_path")
            if [[ ! -d "$dir_path" ]]; then
                error "Directory does not exist: $dir_path"
                return 1
            fi
            if [[ ! -w "$dir_path" ]]; then
                error "Directory is not writable: $dir_path"
                return 1
            fi
            ;;
        execute)
            if [[ ! -x "$file_path" ]]; then
                error "File is not executable: $file_path"
                return 1
            fi
            ;;
        *)
            error "Invalid operation for file validation: $operation"
            return 1
            ;;
    esac
    
    debug "File path validation passed: $file_path ($operation)"
    return 0
}

# Validate output format
validate_output_format() {
    local format="$1"
    local valid_formats=("json" "yaml" "table" "csv")
    
    if [[ -z "$format" ]]; then
        error "Output format is empty"
        return 1
    fi
    
    for valid_format in "${valid_formats[@]}"; do
        if [[ "$format" == "$valid_format" ]]; then
            debug "Output format is valid: $format"
            return 0
        fi
    done
    
    error "Invalid output format: $format"
    info "Valid output formats: ${valid_formats[*]}"
    return 1
}

# Comprehensive prerequisite check
check_prerequisites() {
    local errors=0
    
    header "Checking Prerequisites" "${GEAR}"
    
    # Check confluent CLI
    if ! check_confluent_cli; then
        ((errors++))
    fi
    
    # Check confluent CLI version
    if ! validate_confluent_version; then
        ((errors++))
    fi
    
    # Check authentication
    if ! check_confluent_auth; then
        ((errors++))
    fi
    
    # Check required tools
    local required_tools=("curl" "jq")
    for tool in "${required_tools[@]}"; do
        if ! command_exists "$tool"; then
            warning "$tool is not installed (recommended for full functionality)"
        else
            debug "$tool is available"
        fi
    done
    
    if [[ $errors -gt 0 ]]; then
        error "Prerequisites check failed with $errors error(s)"
        return 1
    fi
    
    success "All prerequisites are satisfied"
    return 0
}

# Validate all environment configuration
validate_all_config() {
    local errors=0
    
    header "Validating Configuration" "${GEAR}"
    
    # Validate environment ID
    if ! validate_environment_id "$CONFLUENT_ENVIRONMENT_ID"; then
        ((errors++))
    fi
    
    # Validate cluster ID
    if ! validate_cluster_id "$CONFLUENT_CLUSTER_ID"; then
        ((errors++))
    fi
    
    # Validate API credentials
    if ! validate_api_key "$CONFLUENT_CLOUD_API_KEY" "Confluent Cloud API key"; then
        ((errors++))
    fi
    
    if ! validate_api_secret "$CONFLUENT_CLOUD_API_SECRET" "Confluent Cloud API secret"; then
        ((errors++))
    fi
    
    # Validate Schema Registry if configured
    if [[ -n "$CONFLUENT_SCHEMA_REGISTRY_URL" ]]; then
        if ! validate_url "$CONFLUENT_SCHEMA_REGISTRY_URL" "Schema Registry URL"; then
            ((errors++))
        fi
        
        if ! validate_api_key "$CONFLUENT_SCHEMA_REGISTRY_API_KEY" "Schema Registry API key"; then
            ((errors++))
        fi
        
        if ! validate_api_secret "$CONFLUENT_SCHEMA_REGISTRY_API_SECRET" "Schema Registry API secret"; then
            ((errors++))
        fi
    fi
    
    # Validate cloud provider
    if [[ -n "$CONFLUENT_CLOUD" ]]; then
        if ! validate_cloud_provider "$CONFLUENT_CLOUD"; then
            ((errors++))
        fi
    fi
    
    if [[ $errors -gt 0 ]]; then
        error "Configuration validation failed with $errors error(s)"
        return 1
    fi
    
    success "All configuration is valid"
    return 0
}

# Test all connectivity
test_all_connectivity() {
    local errors=0
    
    header "Testing Connectivity" "${CLOUD:-☁️}"
    
    # Test Kafka connectivity
    if [[ -n "$CONFLUENT_BOOTSTRAP_SERVERS" ]]; then
        if ! test_connectivity "$CONFLUENT_BOOTSTRAP_SERVERS"; then
            ((errors++))
        fi
    else
        warning "Bootstrap servers not configured, skipping Kafka connectivity test"
    fi
    
    # Test Schema Registry connectivity
    if ! test_schema_registry_connectivity "$CONFLUENT_SCHEMA_REGISTRY_URL" "$CONFLUENT_SCHEMA_REGISTRY_API_KEY" "$CONFLUENT_SCHEMA_REGISTRY_API_SECRET"; then
        ((errors++))
    fi
    
    if [[ $errors -gt 0 ]]; then
        error "Connectivity tests failed with $errors error(s)"
        return 1
    fi
    
    success "All connectivity tests passed"
    return 0
}
