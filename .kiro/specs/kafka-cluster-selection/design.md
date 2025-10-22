# Design Document

## Overview

This design enhances the `discover_kafka_cluster()` function in `bin/confluent-env-export` to support interactive selection when multiple Kafka clusters exist in an environment. The implementation follows the existing pattern used for Flink compute pool selection, ensuring consistency in user experience and code structure.

## Architecture

### Current Implementation

The existing `discover_kafka_cluster()` function:
1. Lists all Kafka clusters using `confluent kafka cluster list -o json`
2. Checks if any clusters exist
3. Automatically selects the first cluster (`.[0]`) from the JSON array
4. Extracts cluster metadata (ID, name, endpoint, region, cloud)

### Proposed Changes

The enhanced function will:
1. List all Kafka clusters (unchanged)
2. Check cluster count
3. **NEW**: If count > 1, display interactive selection menu
4. **NEW**: Prompt user for selection with validation
5. **NEW**: Use selected cluster instead of first cluster
6. If count == 1, auto-select (unchanged)
7. Extract cluster metadata (unchanged)

## Components and Interfaces

### Modified Function: `discover_kafka_cluster()`

**Location**: `bin/confluent-env-export` (approximately line 230)

**Input**: None (uses global environment context)

**Output**: Sets global variables:
- `KAFKA_CLUSTER_ID`
- `KAFKA_CLUSTER_NAME`
- `KAFKA_ENDPOINT`
- `KAFKA_REGION`
- `KAFKA_CLOUD`

**Return Codes**:
- `0`: Success (cluster discovered and selected)
- `1`: Failure (no clusters, API error, or invalid selection)

### Selection Menu Display

The menu will display each cluster with:
- **Index number**: Sequential numbering (1, 2, 3, ...)
- **Cluster name**: Human-readable name
- **Cluster ID**: Unique identifier in parentheses
- **Cloud/Region**: Provider and geographic location
- **Status**: Current cluster state (if available)

**Format Pattern** (matching Flink pool selection):
```
  {CYAN}{index}){RESET} {name} ({BLUE}{id}{RESET}) - {cloud}/{region} [{status}]
```

### User Input Validation

**Valid Input**:
- Numeric string matching regex `^[1-9][0-9]*$`
- Value within range `[1, cluster_count]`

**Invalid Input Handling**:
- Display warning message with valid range
- Re-prompt for input
- Continue loop until valid input received

## Data Models

### Cluster Information Structure

The Confluent CLI returns JSON with the following structure:

```json
[
  {
    "id": "lkc-xxxxx",
    "name": "production-cluster",
    "endpoint": "SASL_SSL://pkc-xxxxx.us-east-1.aws.confluent.cloud:9092",
    "region": "us-east-1",
    "cloud": "AWS",
    "status": "UP",
    "type": "DEDICATED"
  }
]
```

**Fields Used**:
- `id`: Cluster identifier (required)
- `name`: Display name (required)
- `endpoint`: Bootstrap servers (required)
- `region`: Geographic region (required)
- `cloud`: Cloud provider (required)
- `status`: Operational state (optional, defaults to "UNKNOWN")

## Implementation Details

### Code Structure

```bash
discover_kafka_cluster() {
    progress "Checking Kafka cluster"
    
    # 1. List clusters
    local cluster_output
    if ! cluster_output=$(confluent kafka cluster list -o json 2>/dev/null); then
        error "Failed to list Kafka clusters"
        return 1
    fi
    
    # 2. Count clusters
    local cluster_count=$(echo "$cluster_output" | jq 'length')
    if [[ "$cluster_count" -eq 0 ]]; then
        error "No Kafka clusters found in environment: $SELECTED_ENV_NAME"
        return 1
    fi
    
    # 3. Single cluster - auto-select
    if [[ "$cluster_count" -eq 1 ]]; then
        local cluster_info=$(echo "$cluster_output" | jq -r '.[0]')
        # Extract metadata...
        success "Found Kafka cluster: $KAFKA_CLUSTER_NAME ($KAFKA_CLUSTER_ID)"
        return 0
    fi
    
    # 4. Multiple clusters - show menu
    echo -e "${BLUE}${SEARCH} Available Kafka clusters:${RESET}"
    
    local index=1
    echo "$cluster_output" | jq -r '.[] | @json' | while read -r cluster_line; do
        # Extract and display cluster info...
        printf "  ${CYAN}%d)${RESET} %s (${BLUE}%s${RESET}) - %s/%s [%s]\n" \
            "$index" "$cluster_name" "$cluster_id" "$cloud" "$region" "$status"
        ((index++))
    done
    
    # 5. Prompt for selection
    echo
    while true; do
        read -p "$(echo -e "${YELLOW}Select Kafka cluster [1-$cluster_count]:${RESET} ")" choice
        
        if [[ "$choice" =~ ^[1-9][0-9]*$ ]] && [[ $choice -le $cluster_count ]]; then
            local selected_cluster=$(echo "$cluster_output" | jq -r ".[$((choice-1))]")
            # Extract metadata...
            success "Selected Kafka cluster: $KAFKA_CLUSTER_NAME ($KAFKA_CLUSTER_ID)"
            break
        else
            warning "Invalid choice. Please enter a number between 1 and $cluster_count"
        fi
    done
}
```

### Color and Emoji Constants

Uses existing constants from `lib/common.sh`:
- `${BLUE}`: Section headers
- `${CYAN}`: Index numbers
- `${YELLOW}`: Prompts
- `${RESET}`: Color reset
- `${SEARCH}`: Emoji for discovery operations

## Error Handling

### Error Scenarios

1. **CLI Command Failure**
   - Condition: `confluent kafka cluster list` returns non-zero exit code
   - Action: Display error message, return 1
   - Message: "Failed to list Kafka clusters"

2. **No Clusters Found**
   - Condition: JSON array length is 0
   - Action: Display error with environment name, return 1
   - Message: "No Kafka clusters found in environment: {env_name}"

3. **Invalid JSON Response**
   - Condition: `jq` cannot parse response
   - Action: Handled by shell error flags (`-e` in SHELLFLAGS)
   - Result: Script exits with error

4. **Invalid User Input**
   - Condition: Input is not numeric or out of range
   - Action: Display warning, re-prompt
   - Message: "Invalid choice. Please enter a number between 1 and {count}"

### Error Recovery

- **Retry Logic**: User input validation loops until valid input
- **No Automatic Fallback**: Script does not auto-select on invalid input
- **Clear Messaging**: All errors include actionable information

## Testing Strategy

### Manual Testing Scenarios

1. **Single Cluster Environment**
   - Setup: Environment with one Kafka cluster
   - Expected: Auto-select cluster, no prompt
   - Verify: Success message shows correct cluster

2. **Multiple Cluster Environment**
   - Setup: Environment with 2+ Kafka clusters
   - Expected: Display selection menu
   - Verify: All clusters listed with correct metadata

3. **Valid Selection**
   - Setup: Multiple clusters, user enters valid number
   - Expected: Selected cluster used for configuration
   - Verify: Correct cluster ID in generated .env file

4. **Invalid Selection - Non-numeric**
   - Setup: Multiple clusters, user enters "abc"
   - Expected: Warning message, re-prompt
   - Verify: Loop continues until valid input

5. **Invalid Selection - Out of Range**
   - Setup: 3 clusters, user enters "5"
   - Expected: Warning message, re-prompt
   - Verify: Loop continues until valid input

6. **No Clusters**
   - Setup: Empty environment
   - Expected: Error message, script exits
   - Verify: Exit code 1

7. **CLI Failure**
   - Setup: Simulate CLI error (invalid auth)
   - Expected: Error message, script exits
   - Verify: Exit code 1

### Integration Testing

1. **End-to-End Flow**
   - Run `make setup-env` in multi-cluster environment
   - Select cluster from menu
   - Verify complete .env file generation
   - Verify API key creation for selected cluster

2. **Consistency Check**
   - Compare UX with Flink pool selection
   - Verify color scheme matches
   - Verify message formatting matches

### Validation Commands

```bash
# Test cluster listing
confluent kafka cluster list -o json | jq 'length'

# Test cluster metadata extraction
confluent kafka cluster list -o json | jq -r '.[0] | {id, name, endpoint, region, cloud}'

# Test selection logic
# (Manual execution with different inputs)
```

## Backward Compatibility

### No Breaking Changes

- Existing single-cluster environments: No behavior change
- Existing multi-cluster environments: New interactive prompt (enhancement, not breaking)
- Generated .env file format: Unchanged
- Global variable names: Unchanged
- Function signature: Unchanged

### Migration Path

No migration required. The enhancement is transparent to existing workflows.

## Performance Considerations

### Minimal Impact

- **API Calls**: No additional API calls (same `confluent kafka cluster list`)
- **Processing**: Negligible overhead for JSON parsing and menu display
- **User Interaction**: Only adds delay when user makes selection (intentional)

### Optimization

- JSON parsing done once, reused for display and selection
- No redundant API calls for cluster metadata

## Security Considerations

### No New Security Risks

- No additional credential handling
- No new file permissions
- No new network calls
- User input validation prevents injection (numeric-only)

### Existing Security Measures

- Maintains existing .env file permissions (600)
- Maintains existing API key handling
- Maintains existing credential storage patterns

## Future Enhancements

### Potential Improvements

1. **Default Cluster Selection**: Add flag to specify cluster by name/ID
2. **Cluster Filtering**: Filter by cloud provider, region, or type
3. **Cluster Details**: Show additional metadata (type, capacity, pricing)
4. **Non-Interactive Mode**: Support `--cluster-id` flag for automation
5. **Cluster Comparison**: Display side-by-side comparison of clusters

### Extension Points

The design allows for easy extension:
- Additional cluster metadata can be displayed by modifying the `printf` format
- Filtering logic can be added before the selection menu
- Default selection logic can be added with minimal changes
