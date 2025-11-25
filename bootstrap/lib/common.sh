#!/bin/bash

#######################################
# Common Utilities for Bootstrap System
# Provides logging, error handling, and shared functions
#######################################

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Source guard - only define colors if not already defined
if [[ -z "${RED:-}" ]]; then
    # Colors for output
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[1;33m'
    readonly BLUE='\033[0;34m'
    readonly MAGENTA='\033[0;35m'
    readonly CYAN='\033[0;36m'
    readonly NC='\033[0m' # No Color
fi

# Global flags
VERBOSE="${VERBOSE:-false}"
NON_INTERACTIVE="${NON_INTERACTIVE:-false}"

#######################################
# Logging Functions
#######################################

# Log info message
# Arguments:
#   $1 - Message to log
log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Log success message
# Arguments:
#   $1 - Message to log
log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Log warning message
# Arguments:
#   $1 - Message to log
log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Log error message to stderr
# Arguments:
#   $1 - Message to log
log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
}

# Log debug message (only in verbose mode)
# Arguments:
#   $1 - Message to log
log_debug() {
    if [[ "${VERBOSE}" == "true" ]]; then
        echo -e "${MAGENTA}[DEBUG]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
    fi
}

# Log step header
# Arguments:
#   $1 - Step description
log_step() {
    echo ""
    echo -e "${CYAN}===================================================${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}===================================================${NC}"
}

#######################################
# Utility Functions
#######################################

# Check if a command exists
# Arguments:
#   $1 - Command name
# Returns:
#   0 if command exists, 1 otherwise
check_command() {
    command -v "$1" >/dev/null 2>&1
}

# Run command with retry logic
# Arguments:
#   $1 - Command to run
#   $2 - Max attempts (optional, default: 3)
#   $3 - Delay between retries in seconds (optional, default: 2)
# Returns:
#   0 if command succeeds, 1 if all retries fail
run_with_retry() {
    local cmd="$1"
    local max_attempts="${2:-3}"
    local delay="${3:-2}"
    local attempt=1
    
    while [ $attempt -le "$max_attempts" ]; do
        log_debug "Attempt $attempt/$max_attempts: $cmd"
        
        if eval "$cmd"; then
            return 0
        fi
        
        if [ $attempt -lt "$max_attempts" ]; then
            log_warn "Attempt $attempt/$max_attempts failed, retrying in ${delay}s..."
            sleep "$delay"
        fi
        
        attempt=$((attempt + 1))
    done
    
    log_error "Command failed after $max_attempts attempts: $cmd"
    return 1
}

# Create timestamped backup of a file
# Arguments:
#   $1 - File path to backup
# Returns:
#   0 if backup created, 1 if file doesn't exist
backup_file() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        log_debug "No file to backup: $file"
        return 1
    fi
    
    local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$file" "$backup"
    log_info "Backup created: $backup"
    return 0
}

# Validate JSON file
# Arguments:
#   $1 - JSON file path
# Returns:
#   0 if valid JSON, 1 otherwise
validate_json() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        log_error "File not found: $file"
        return 1
    fi
    
    if ! check_command jq; then
        log_error "jq is required for JSON validation but not installed"
        return 1
    fi
    
    if ! jq empty "$file" 2>/dev/null; then
        log_error "Invalid JSON in $file"
        return 1
    fi
    
    log_debug "Valid JSON: $file"
    return 0
}

# Detect operating system
# Returns:
#   OS identifier (ubuntu, debian, centos, fedora, etc.)
detect_os() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        echo "$ID"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

# Detect OS version
# Returns:
#   Version string
detect_os_version() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        echo "$VERSION_ID"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        sw_vers -productVersion
    else
        echo "unknown"
    fi
}

# Detect user's shell
# Returns:
#   Shell name (bash, zsh, etc.)
detect_shell() {
    basename "$SHELL"
}

# Get shell config file path
# Returns:
#   Path to shell config file
get_shell_config() {
    local shell
    shell=$(detect_shell)
    
    case "$shell" in
        bash)
            if [[ -f "$HOME/.bashrc" ]]; then
                echo "$HOME/.bashrc"
            else
                echo "$HOME/.bash_profile"
            fi
            ;;
        zsh)
            echo "$HOME/.zshrc"
            ;;
        *)
            log_warn "Unknown shell: $shell, defaulting to .bashrc"
            echo "$HOME/.bashrc"
            ;;
    esac
}

# Confirm action with user (unless non-interactive)
# Arguments:
#   $1 - Prompt message
#   $2 - Default answer (y/n, optional, default: n)
# Returns:
#   0 if confirmed, 1 otherwise
confirm() {
    local prompt="$1"
    local default="${2:-n}"
    
    if [[ "${NON_INTERACTIVE}" == "true" ]]; then
        log_debug "Non-interactive mode, using default: $default"
        [[ "$default" == "y" ]] && return 0 || return 1
    fi
    
    local response
    read -r -p "$prompt [y/N]: " response
    response=${response:-$default}
    
    [[ "$response" =~ ^[Yy]$ ]] && return 0 || return 1
}

# Check if running as root
# Returns:
#   0 if root, 1 otherwise
is_root() {
    [[ $EUID -eq 0 ]]
}

# Ensure running as root, exit if not
require_root() {
    if ! is_root; then
        log_error "This script must be run as root"
        exit 1
    fi
}

# Ensure NOT running as root, exit if root
require_non_root() {
    if is_root; then
        log_error "This script should not be run as root"
        exit 1
    fi
}

# Check if running in Docker container
# Returns:
#   0 if in container, 1 otherwise
is_docker() {
    [[ -f /.dockerenv ]] || grep -q docker /proc/1/cgroup 2>/dev/null
}

# Create directory if it doesn't exist
# Arguments:
#   $1 - Directory path
ensure_directory() {
    local dir="$1"
    
    if [[ ! -d "$dir" ]]; then
        log_debug "Creating directory: $dir"
        mkdir -p "$dir"
    fi
}

# Download file with progress
# Arguments:
#   $1 - URL
#   $2 - Output file path
# Returns:
#   0 if successful, 1 otherwise
download_file() {
    local url="$1"
    local output="$2"
    
    log_info "Downloading: $url"
    
    if check_command curl; then
        curl -fsSL -o "$output" "$url"
    elif check_command wget; then
        wget -q -O "$output" "$url"
    else
        log_error "Neither curl nor wget is available"
        return 1
    fi
}

# Get absolute path of a file/directory
# Arguments:
#   $1 - Path (relative or absolute)
# Returns:
#   Absolute path
get_absolute_path() {
    local path="$1"
    
    if [[ -d "$path" ]]; then
        (cd "$path" && pwd)
    elif [[ -f "$path" ]]; then
        local dir
        local file
        dir=$(dirname "$path")
        file=$(basename "$path")
        echo "$(cd "$dir" && pwd)/$file"
    else
        # Path doesn't exist yet, resolve parent
        local dir
        local file
        dir=$(dirname "$path")
        file=$(basename "$path")
        if [[ -d "$dir" ]]; then
            echo "$(cd "$dir" && pwd)/$file"
        else
            echo "$path"
        fi
    fi
}

# Generate random string
# Arguments:
#   $1 - Length (optional, default: 32)
# Returns:
#   Random alphanumeric string
generate_random_string() {
    local length="${1:-32}"
    
    if check_command openssl; then
        openssl rand -base64 "$length" | tr -d "=+/" | cut -c1-"$length"
    else
        # Fallback to /dev/urandom
        tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c "$length"
    fi
}

# Check if port is available
# Arguments:
#   $1 - Port number
# Returns:
#   0 if available, 1 if in use
is_port_available() {
    local port="$1"
    
    if check_command nc; then
        ! nc -z localhost "$port" 2>/dev/null
    elif check_command lsof; then
        ! lsof -i:"$port" >/dev/null 2>&1
    else
        log_warn "Cannot check port availability (nc or lsof required)"
        return 0  # Assume available
    fi
}

# Wait for port to be available
# Arguments:
#   $1 - Port number
#   $2 - Timeout in seconds (optional, default: 30)
# Returns:
#   0 if port becomes available, 1 if timeout
wait_for_port() {
    local port="$1"
    local timeout="${2:-30}"
    local elapsed=0
    
    log_info "Waiting for port $port to become available..."
    
    while ! is_port_available "$port"; do
        if [ $elapsed -ge "$timeout" ]; then
            log_error "Timeout waiting for port $port"
            return 1
        fi
        
        sleep 1
        elapsed=$((elapsed + 1))
    done
    
    log_success "Port $port is available"
    return 0
}

# Cleanup function to be called on exit
# Arguments:
#   $1 - Exit code
cleanup() {
    local exit_code="${1:-0}"
    
    log_debug "Cleanup called with exit code: $exit_code"
    
    # Add cleanup tasks here
    # Remove temporary files, restore backups, etc.
    
    exit "$exit_code"
}

# Setup trap for cleanup on exit
setup_cleanup_trap() {
    trap 'cleanup $?' EXIT
    trap 'cleanup 130' INT  # Ctrl+C
    trap 'cleanup 143' TERM # Termination
}

#######################################
# Initialization
#######################################

# Export functions for use in other scripts
export -f log_info
export -f log_success
export -f log_warn
export -f log_error
export -f log_debug
export -f log_step
export -f check_command
export -f run_with_retry
export -f backup_file
export -f validate_json
export -f detect_os
export -f detect_os_version
export -f detect_shell
export -f get_shell_config
export -f confirm
export -f is_root
export -f require_root
export -f require_non_root
export -f is_docker
export -f ensure_directory
export -f download_file
export -f get_absolute_path
export -f generate_random_string
export -f is_port_available
export -f wait_for_port
export -f cleanup
export -f setup_cleanup_trap

log_debug "common.sh loaded successfully"
