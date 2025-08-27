#!/bin/bash
# lib/common.sh - Common functions and variables for Confluent Cloud utilities

# Color definitions
export RED='\033[31m'
export GREEN='\033[32m'
export YELLOW='\033[33m'
export BLUE='\033[34m'
export MAGENTA='\033[35m'
export CYAN='\033[36m'
export WHITE='\033[37m'
export RESET='\033[0m'

# Emoji definitions
export CHECK='✅'
export ROCKET='🚀'
export GEAR='⚙️'
export WARNING='⚠️'
export ERROR='❌'
export CLEAN='🧹'
export INFO='ℹ️'
export KEY='🔑'
export CLOUD='☁️'
export LOCK='🔐'
export SYNC='🔄'
export HEALTH='💚'
export AUDIT='🔍'
export BACKUP='💾'
export TEST='🧪'
export PACKAGE='📦'

# Logging functions with consistent formatting
error() {
    echo -e "${RED}${ERROR} ERROR:${RESET} $1" >&2
}

success() {
    echo -e "${GREEN}${CHECK} SUCCESS:${RESET} $1"
}

warning() {
    echo -e "${YELLOW}${WARNING} WARNING:${RESET} $1"
}

info() {
    echo -e "${BLUE}${INFO} INFO:${RESET} $1"
}

debug() {
    if [[ "${CC_DEBUG:-}" == "true" ]]; then
        echo -e "${MAGENTA}🐛 DEBUG:${RESET} $1" >&2
    fi
}

# Progress indicator function
progress() {
    local message="$1"
    echo -e "${CYAN}${GEAR} ${message}...${RESET}"
}

# Header function for utility output
header() {
    local title="$1"
    local emoji="${2:-${GEAR}}"
    echo
    echo -e "${BLUE}${emoji} ${title}${RESET}"
    echo -e "${BLUE}$(printf '=%.0s' $(seq 1 $((${#title} + 4))))${RESET}"
}

# Confirmation prompt with colored output
confirm() {
    local message="$1"
    local default="${2:-n}"
    
    if [[ "${CC_FORCE:-}" == "true" ]]; then
        info "Force mode enabled, skipping confirmation"
        return 0
    fi
    
    local prompt
    if [[ "$default" == "y" ]]; then
        prompt="${YELLOW}${WARNING} ${message} [Y/n]:${RESET} "
    else
        prompt="${YELLOW}${WARNING} ${message} [y/N]:${RESET} "
    fi
    
    read -p "$(echo -e "$prompt")" -r response
    
    case "$response" in
        [yY]|[yY][eE][sS])
            return 0
            ;;
        [nN]|[nN][oO])
            return 1
            ;;
        "")
            if [[ "$default" == "y" ]]; then
                return 0
            else
                return 1
            fi
            ;;
        *)
            warning "Invalid response. Please answer y or n."
            confirm "$message" "$default"
            ;;
    esac
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if we're in quiet mode
is_quiet() {
    [[ "${CC_QUIET:-}" == "true" ]]
}

# Check if we're in verbose mode
is_verbose() {
    [[ "${CC_VERBOSE:-}" == "true" ]]
}

# Check if we're in dry-run mode
is_dry_run() {
    [[ "${CC_DRY_RUN:-}" == "true" ]]
}

# Dry run wrapper
dry_run() {
    local command="$1"
    if is_dry_run; then
        info "DRY RUN: Would execute: $command"
    else
        eval "$command"
    fi
}

# Spinner function for long-running operations
spinner() {
    local pid=$1
    local message="${2:-Processing}"
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    if is_quiet; then
        wait "$pid"
        return $?
    fi
    
    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i+1) %10 ))
        printf "\r%s%s %s...%s" "${CYAN}" "${spin:$i:1}" "${message}" "${RESET}"
        sleep 0.1
    done
    
    wait "$pid"
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        printf "\r%s%s %s completed%s\n" "${GREEN}" "${CHECK}" "${message}" "${RESET}"
    else
        printf "\r%s%s %s failed%s\n" "${RED}" "${ERROR}" "${message}" "${RESET}"
    fi
    
    return $exit_code
}

# Cleanup function for temporary files
cleanup() {
    local temp_files=("$@")
    for file in "${temp_files[@]}"; do
        if [[ -f "$file" ]]; then
            rm -f "$file"
            debug "Cleaned up temporary file: $file"
        fi
    done
}

# Set up trap for cleanup on exit
setup_cleanup() {
    local temp_files=("$@")
    trap 'cleanup "${temp_files[@]}"' EXIT INT TERM
}

# Version comparison function
version_compare() {
    local version1="$1"
    local version2="$2"
    
    if [[ "$version1" == "$version2" ]]; then
        return 0
    fi
    
    local IFS=.
    local i
    local -a ver1 ver2
    IFS='.' read -ra ver1 <<< "$version1"
    IFS='.' read -ra ver2 <<< "$version2"
    
    # Fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do
        ver1[i]=0
    done
    
    for ((i=0; i<${#ver1[@]}; i++)); do
        if [[ -z ${ver2[i]} ]]; then
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]})); then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]})); then
            return 2
        fi
    done
    
    return 0
}

# Initialize common variables
init_common() {
    # Set default values for common variables
    export CC_CONFIG_DIR="${CC_CONFIG_DIR:-$HOME/.confluent}"
    export CC_DEFAULT_OUTPUT_FORMAT="${CC_DEFAULT_OUTPUT_FORMAT:-table}"
    export CC_DEBUG="${CC_DEBUG:-false}"
    export CC_QUIET="${CC_QUIET:-false}"
    export CC_VERBOSE="${CC_VERBOSE:-false}"
    export CC_DRY_RUN="${CC_DRY_RUN:-false}"
    export CC_FORCE="${CC_FORCE:-false}"
    
    # Create config directory if it doesn't exist
    if [[ ! -d "$CC_CONFIG_DIR" ]]; then
        mkdir -p "$CC_CONFIG_DIR"
        debug "Created config directory: $CC_CONFIG_DIR"
    fi
}

# Initialize common settings when sourced
init_common
