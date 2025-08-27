#!/bin/bash
# lib/output.sh - Output formatting functions for different formats

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/common.sh"

# JSON output functions
output_json() {
    local data="$1"
    
    if command_exists jq; then
        echo "$data" | jq .
    else
        echo "$data"
    fi
}

# Create JSON object from key-value pairs
json_object() {
    local key value
    local json="{"
    local first=true
    
    # Parse key=value pairs
    for arg in "$@"; do
        if [[ "$arg" =~ ^([^=]+)=(.*)$ ]]; then
            key="${BASH_REMATCH[1]}"
            value="${BASH_REMATCH[2]}"
            
            if [[ "$first" == "true" ]]; then
                first=false
            else
                json+=","
            fi
            json+="\"$key\":\"$value\""
        fi
    done
    json+="}"
    
    echo "$json"
}

# Create JSON array from values
json_array() {
    local json="["
    local first=true
    
    while [[ $# -gt 0 ]]; do
        if [[ "$first" == "true" ]]; then
            first=false
        else
            json+=","
        fi
        json+="\"$1\""
        shift
    done
    
    json+="]"
    echo "$json"
}

# YAML output functions
output_yaml() {
    local data="$1"
    
    if command_exists yq; then
        echo "$data" | yq .
    else
        # Simple YAML conversion if yq is not available
        echo "$data" | sed 's/^/  /' | sed '1s/^  //'
    fi
}

# CSV output functions
output_csv() {
    local headers="$1"
    shift
    local rows=("$@")
    
    # Output headers
    echo "$headers"
    
    # Output rows
    for row in "${rows[@]}"; do
        echo "$row"
    done
}

# Escape CSV field
csv_escape() {
    local field="$1"
    
    # If field contains comma, quote, or newline, wrap in quotes and escape quotes
    if [[ "$field" == *","* || "$field" == *"\""* || "$field" == *$'\n'* ]]; then
        field="\"${field//\"/\"\"}\""
    fi
    
    echo "$field"
}

# Table output functions
output_table() {
    local headers="$1"
    shift
    local rows=("$@")
    
    # Calculate column widths
    local -a col_widths
    local -a header_array
    
    IFS=',' read -ra header_array <<< "$headers"
    
    # Initialize column widths with header lengths
    for i in "${!header_array[@]}"; do
        col_widths[i]=${#header_array[i]}
    done
    
    # Calculate maximum width for each column
    for row in "${rows[@]}"; do
        IFS=',' read -ra row_array <<< "$row"
        for i in "${!row_array[@]}"; do
            if [[ ${#row_array[i]} -gt ${col_widths[i]:-0} ]]; then
                col_widths[i]=${#row_array[i]}
            fi
        done
    done
    
    # Output table header
    local separator=""
    local header_line=""
    
    for i in "${!header_array[@]}"; do
        local width=${col_widths[i]}
        local header="${header_array[i]}"
        
        if [[ $i -gt 0 ]]; then
            header_line+=" | "
            separator+="-+-"
        fi
        
        header_line+="$(printf "%-${width}s" "$header")"
        separator+="$(printf "%*s" "$width" "" | tr ' ' '-')"
    done
    
    echo -e "${BLUE}$header_line${RESET}"
    echo -e "${BLUE}$separator${RESET}"
    
    # Output table rows
    for row in "${rows[@]}"; do
        IFS=',' read -ra row_array <<< "$row"
        local row_line=""
        
        for i in "${!row_array[@]}"; do
            local width=${col_widths[i]:-10}
            local cell="${row_array[i]}"
            
            if [[ $i -gt 0 ]]; then
                row_line+=" | "
            fi
            
            row_line+="$(printf "%-${width}s" "$cell")"
        done
        
        echo "$row_line"
    done
}

# Colorized table output with status indicators
output_status_table() {
    local headers="$1"
    shift
    local rows=("$@")
    
    # Similar to output_table but with status color coding
    local -a col_widths
    local -a header_array
    
    IFS=',' read -ra header_array <<< "$headers"
    
    # Initialize column widths with header lengths
    for i in "${!header_array[@]}"; do
        col_widths[i]=${#header_array[i]}
    done
    
    # Calculate maximum width for each column (excluding color codes)
    for row in "${rows[@]}"; do
        IFS=',' read -ra row_array <<< "$row"
        for i in "${!row_array[@]}"; do
            # Remove color codes for length calculation
            local clean_cell="${row_array[i]//\\033\[[0-9;]*m/}"
            if [[ ${#clean_cell} -gt ${col_widths[i]:-0} ]]; then
                col_widths[i]=${#clean_cell}
            fi
        done
    done
    
    # Output table header
    local separator=""
    local header_line=""
    
    for i in "${!header_array[@]}"; do
        local width=${col_widths[i]}
        local header="${header_array[i]}"
        
        if [[ $i -gt 0 ]]; then
            header_line+=" | "
            separator+="-+-"
        fi
        
        header_line+="$(printf "%-${width}s" "$header")"
        separator+="$(printf "%*s" "$width" "" | tr ' ' '-')"
    done
    
    echo -e "${BLUE}$header_line${RESET}"
    echo -e "${BLUE}$separator${RESET}"
    
    # Output table rows with color preservation
    for row in "${rows[@]}"; do
        IFS=',' read -ra row_array <<< "$row"
        local row_line=""
        
        for i in "${!row_array[@]}"; do
            local width=${col_widths[i]:-10}
            local cell="${row_array[i]}"
            local clean_cell="${cell//\\033\[[0-9;]*m/}"
            local padding=$((width - ${#clean_cell}))
            
            if [[ $i -gt 0 ]]; then
                row_line+=" | "
            fi
            
            row_line+="$cell$(printf "%*s" $padding)"
        done
        
        echo -e "$row_line"
    done
}

# Format status with color and emoji
format_status() {
    local status="$1"
    
    case "${status,,}" in
        active|running|healthy|valid|success|ok)
            echo -e "${GREEN}${CHECK} $status${RESET}"
            ;;
        inactive|stopped|unhealthy|invalid|failed|error)
            echo -e "${RED}${ERROR} $status${RESET}"
            ;;
        pending|processing|warning)
            echo -e "${YELLOW}${WARNING} $status${RESET}"
            ;;
        unknown|n/a|-)
            echo -e "${BLUE}${INFO} $status${RESET}"
            ;;
        *)
            echo "$status"
            ;;
    esac
}

# Format timestamp
format_timestamp() {
    local timestamp="$1"
    local format="${2:-%Y-%m-%d %H:%M:%S}"
    
    if [[ -n "$timestamp" ]]; then
        if command_exists date; then
            date -d "$timestamp" +"$format" 2>/dev/null || echo "$timestamp"
        else
            echo "$timestamp"
        fi
    else
        echo "N/A"
    fi
}

# Format file size
format_size() {
    local size="$1"
    
    if [[ -z "$size" || "$size" == "0" ]]; then
        echo "0 B"
        return
    fi
    
    local units=("B" "KB" "MB" "GB" "TB")
    local unit_index=0
    local size_float=$size
    
    while (( $(echo "$size_float >= 1024" | bc -l 2>/dev/null || echo "0") )) && [[ $unit_index -lt $((${#units[@]} - 1)) ]]; do
        size_float=$(echo "scale=1; $size_float / 1024" | bc -l 2>/dev/null || echo "$size_float")
        ((unit_index++))
    done
    
    printf "%.1f %s" "$size_float" "${units[$unit_index]}"
}

# Output data in specified format
output_data() {
    local format="$1"
    local data="$2"
    shift 2
    
    case "${format,,}" in
        json)
            output_json "$data"
            ;;
        yaml|yml)
            output_yaml "$data"
            ;;
        csv)
            output_csv "$@"
            ;;
        table)
            output_table "$@"
            ;;
        status-table)
            output_status_table "$@"
            ;;
        *)
            error "Unsupported output format: $format"
            return 1
            ;;
    esac
}

# Create a simple progress bar
progress_bar() {
    local current="$1"
    local total="$2"
    local width="${3:-50}"
    local prefix="${4:-Progress}"
    
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    local bar=""
    for ((i=0; i<filled; i++)); do
        bar+="█"
    done
    for ((i=0; i<empty; i++)); do
        bar+="░"
    done
    
    printf "\r${CYAN}%s: [%s] %d%% (%d/%d)${RESET}" "$prefix" "$bar" "$percentage" "$current" "$total"
    
    if [[ $current -eq $total ]]; then
        echo  # New line when complete
    fi
}

# Display a summary box
summary_box() {
    local title="$1"
    shift
    local items=("$@")
    
    local max_length=${#title}
    for item in "${items[@]}"; do
        # Remove color codes for length calculation
        local clean_item="${item//\\033\[[0-9;]*m/}"
        if [[ ${#clean_item} -gt $max_length ]]; then
            max_length=${#clean_item}
        fi
    done
    
    local box_width=$((max_length + 4))
    local border
    border=$(printf "%*s" "$box_width" "" | tr ' ' '─')
    
    echo -e "${BLUE}┌${border}┐${RESET}"
    echo -e "${BLUE}│${RESET} $(printf "%-${max_length}s" "$title") ${BLUE}│${RESET}"
    echo -e "${BLUE}├${border}┤${RESET}"
    
    for item in "${items[@]}"; do
        local clean_item="${item//\\033\[[0-9;]*m/}"
        local padding=$((max_length - ${#clean_item}))
        echo -e "${BLUE}│${RESET} $item$(printf "%*s" $padding) ${BLUE}│${RESET}"
    done
    
    echo -e "${BLUE}└${border}┘${RESET}"
}

# Display key-value pairs in a formatted way
display_key_value() {
    local key value max_key_length=0
    local keys=() values=()
    
    # Parse key=value pairs and find max key length
    for arg in "$@"; do
        if [[ "$arg" =~ ^([^=]+)=(.*)$ ]]; then
            key="${BASH_REMATCH[1]}"
            value="${BASH_REMATCH[2]}"
            keys+=("$key")
            values+=("$value")
            if [[ ${#key} -gt $max_key_length ]]; then
                max_key_length=${#key}
            fi
        fi
    done
    
    # Display formatted pairs
    for i in "${!keys[@]}"; do
        printf "  ${CYAN}%-${max_key_length}s${RESET}: %s\n" "${keys[$i]}" "${values[$i]}"
    done
}

# Initialize output settings
init_output() {
    # Check for required tools and warn if missing
    if ! command_exists jq; then
        debug "jq not found - JSON output will be unformatted"
    fi
    
    if ! command_exists yq; then
        debug "yq not found - YAML output will be basic"
    fi
    
    if ! command_exists bc; then
        debug "bc not found - some calculations may be limited"
    fi
}
