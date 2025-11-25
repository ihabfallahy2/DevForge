#!/bin/bash

#######################################
# Project Detection and Configuration
# Detects project type and reads bootstrap configuration
#######################################

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/common.sh"

#######################################
# Configuration File
#######################################

readonly BOOTSTRAP_CONFIG_FILE="project.bootstrap.json"

#######################################
# Project Type Detection
#######################################

# Detect project type from files and structure
# Arguments:
#   $1 - Project directory path
# Returns:
#   Project type (spring-boot, nodejs, python, generic)
detect_project_type() {
    local project_dir="$1"
    
    log_debug "Detecting project type in: $project_dir"
    
    # Check for bootstrap config first
    if [[ -f "$project_dir/$BOOTSTRAP_CONFIG_FILE" ]]; then
        local type
        type=$(jq -r '.type // "generic"' "$project_dir/$BOOTSTRAP_CONFIG_FILE" 2>/dev/null)
        if [[ -n "$type" && "$type" != "null" ]]; then
            log_info "Project type from config: $type"
            echo "$type"
            return 0
        fi
    fi
    
    # Heuristic detection based on files
    if [[ -f "$project_dir/pom.xml" ]] || [[ -f "$project_dir/build.gradle" ]]; then
        # Check if it's Spring Boot
        if grep -q "spring-boot" "$project_dir/pom.xml" 2>/dev/null || \
           grep -q "spring-boot" "$project_dir/build.gradle" 2>/dev/null; then
            log_info "Detected Spring Boot project"
            echo "spring-boot"
            return 0
        fi
        log_info "Detected Java project"
        echo "java"
        return 0
    fi
    
    if [[ -f "$project_dir/package.json" ]]; then
        log_info "Detected Node.js project"
        echo "nodejs"
        return 0
    fi
    
    if [[ -f "$project_dir/requirements.txt" ]] || \
       [[ -f "$project_dir/setup.py" ]] || \
       [[ -f "$project_dir/pyproject.toml" ]]; then
        log_info "Detected Python project"
        echo "python"
        return 0
    fi
    
    if [[ -f "$project_dir/go.mod" ]]; then
        log_info "Detected Go project"
        echo "go"
        return 0
    fi
    
    if [[ -f "$project_dir/Cargo.toml" ]]; then
        log_info "Detected Rust project"
        echo "rust"
        return 0
    fi
    
    if [[ -f "$project_dir/Gemfile" ]]; then
        log_info "Detected Ruby project"
        echo "ruby"
        return 0
    fi
    
    if [[ -f "$project_dir/composer.json" ]]; then
        log_info "Detected PHP project"
        echo "php"
        return 0
    fi
    
    log_warn "Could not detect project type, using generic"
    echo "generic"
    return 0
}

#######################################
# Bootstrap Configuration
#######################################

# Read bootstrap configuration file
# Arguments:
#   $1 - Project directory path
# Returns:
#   0 if config exists and is valid, 1 otherwise
read_bootstrap_config() {
    local project_dir="$1"
    local config_file="$project_dir/$BOOTSTRAP_CONFIG_FILE"
    
    if [[ ! -f "$config_file" ]]; then
        log_warn "Bootstrap config not found: $config_file"
        return 1
    fi
    
    if ! validate_json "$config_file"; then
        log_error "Invalid bootstrap configuration"
        return 1
    fi
    
    log_success "Bootstrap configuration loaded: $config_file"
    return 0
}

# Validate bootstrap configuration schema
# Arguments:
#   $1 - Project directory path
# Returns:
#   0 if valid, 1 otherwise
validate_bootstrap_config() {
    local project_dir="$1"
    local config_file="$project_dir/$BOOTSTRAP_CONFIG_FILE"
    
    if [[ ! -f "$config_file" ]]; then
        log_debug "No bootstrap config to validate"
        return 1
    fi
    
    # Check required fields
    local required_fields=("name" "type")
    local field
    
    for field in "${required_fields[@]}"; do
        local value
        value=$(jq -r ".$field // empty" "$config_file" 2>/dev/null)
        
        if [[ -z "$value" || "$value" == "null" ]]; then
            log_error "Missing required field in bootstrap config: $field"
            return 1
        fi
    done
    
    log_debug "Bootstrap configuration is valid"
    return 0
}

# Get value from bootstrap config
# Arguments:
#   $1 - Project directory path
#   $2 - JSON path (e.g., ".name", ".dependencies.system")
#   $3 - Default value (optional)
# Returns:
#   Config value or default
get_config_value() {
    local project_dir="$1"
    local json_path="$2"
    local default="${3:-}"
    local config_file="$project_dir/$BOOTSTRAP_CONFIG_FILE"
    
    if [[ ! -f "$config_file" ]]; then
        echo "$default"
        return 0
    fi
    
    local value
    value=$(jq -r "${json_path} // empty" "$config_file" 2>/dev/null)
    
    if [[ -z "$value" || "$value" == "null" ]]; then
        echo "$default"
    else
        echo "$value"
    fi
}

# Get array from bootstrap config
# Arguments:
#   $1 - Project directory path
#   $2 - JSON path (e.g., ".dependencies.system")
# Returns:
#   Array elements, one per line
get_config_array() {
    local project_dir="$1"
    local json_path="$2"
    local config_file="$project_dir/$BOOTSTRAP_CONFIG_FILE"
    
    if [[ ! -f "$config_file" ]]; then
        return 0
    fi
    
    jq -r "${json_path}[]? // empty" "$config_file" 2>/dev/null
}

#######################################
# Dependency Management
#######################################

# Get required system dependencies
# Arguments:
#   $1 - Project directory path
# Returns:
#   List of dependencies, one per line
get_required_dependencies() {
    local project_dir="$1"
    
    log_debug "Getting required dependencies for: $project_dir"
    
    # Get from config if available
    local deps
    deps=$(get_config_array "$project_dir" ".dependencies.system")
    
    if [[ -n "$deps" ]]; then
        echo "$deps"
        return 0
    fi
    
    # Fallback to defaults based on project type
    local project_type
    project_type=$(detect_project_type "$project_dir")
    
    case "$project_type" in
        spring-boot|java)
            echo "docker"
            echo "docker-compose"
            echo "git"
            ;;
        nodejs)
            echo "docker"
            echo "docker-compose"
            echo "git"
            echo "nodejs"
            ;;
        python)
            echo "docker"
            echo "docker-compose"
            echo "git"
            echo "python3"
            ;;
        go)
            echo "docker"
            echo "docker-compose"
            echo "git"
            echo "go"
            ;;
        *)
            echo "docker"
            echo "docker-compose"
            echo "git"
            ;;
    esac
}

# Get required runtime dependencies
# Arguments:
#   $1 - Project directory path
# Returns:
#   List of runtime dependencies, one per line
get_runtime_dependencies() {
    local project_dir="$1"
    
    log_debug "Getting runtime dependencies for: $project_dir"
    
    # Get from config if available
    local deps
    deps=$(get_config_array "$project_dir" ".dependencies.runtime")
    
    if [[ -n "$deps" ]]; then
        echo "$deps"
        return 0
    fi
    
    # Fallback to defaults based on project type
    local project_type
    project_type=$(detect_project_type "$project_dir")
    
    case "$project_type" in
        spring-boot|java)
            echo "java-17"
            ;;
        nodejs)
            echo "node-18"
            ;;
        python)
            echo "python-3.11"
            ;;
        *)
            # No runtime dependencies for generic projects
            ;;
    esac
}

# Get optional dependencies
# Arguments:
#   $1 - Project directory path
# Returns:
#   List of optional dependencies, one per line
get_optional_dependencies() {
    local project_dir="$1"
    
    get_config_array "$project_dir" ".dependencies.optional"
}

#######################################
# Service Detection
#######################################

# Get required database services
# Arguments:
#   $1 - Project directory path
# Returns:
#   List of databases, one per line
get_required_databases() {
    local project_dir="$1"
    
    get_config_array "$project_dir" ".services.databases"
}

# Get required cache services
# Arguments:
#   $1 - Project directory path
# Returns:
#   List of cache services, one per line
get_required_cache() {
    local project_dir="$1"
    
    get_config_array "$project_dir" ".services.cache"
}

# Get required queue services
# Arguments:
#   $1 - Project directory path
# Returns:
#   List of queue services, one per line
get_required_queues() {
    local project_dir="$1"
    
    get_config_array "$project_dir" ".services.queues"
}

#######################################
# Secrets Configuration
#######################################

# Get secrets vault name
# Arguments:
#   $1 - Project directory path
#   $2 - Environment (prod, dev, staging)
# Returns:
#   Vault name
get_secrets_vault() {
    local project_dir="$1"
    local env="${2:-prod}"
    
    # Try environment-specific vault first
    local vault
    vault=$(get_config_value "$project_dir" ".secrets.vault_${env}")
    
    if [[ -n "$vault" ]]; then
        echo "$vault"
        return 0
    fi
    
    # Fallback to default vault
    vault=$(get_config_value "$project_dir" ".secrets.vault")
    
    if [[ -n "$vault" ]]; then
        echo "$vault"
        return 0
    fi
    
    # Generate default vault name
    local project_name
    project_name=$(get_config_value "$project_dir" ".name" "project")
    echo "${project_name}-${env}"
}

# Get required secrets
# Arguments:
#   $1 - Project directory path
# Returns:
#   List of required secret names, one per line
get_required_secrets() {
    local project_dir="$1"
    
    get_config_array "$project_dir" ".secrets.required"
}

# Get optional secrets
# Arguments:
#   $1 - Project directory path
# Returns:
#   List of optional secret names, one per line
get_optional_secrets() {
    local project_dir="$1"
    
    get_config_array "$project_dir" ".secrets.optional"
}

#######################################
# Hooks
#######################################

# Get hook command
# Arguments:
#   $1 - Project directory path
#   $2 - Hook name (pre-clone, post-clone, pre-secrets, post-secrets, pre-deploy, post-deploy, health-check)
# Returns:
#   Hook command or empty string
get_hook_command() {
    local project_dir="$1"
    local hook_name="$2"
    
    get_config_value "$project_dir" ".hooks.\"${hook_name}\""
}

# Execute hook if defined
# Arguments:
#   $1 - Project directory path
#   $2 - Hook name
# Returns:
#   0 if hook succeeds or doesn't exist, 1 if hook fails
execute_hook() {
    local project_dir="$1"
    local hook_name="$2"
    
    local hook_cmd
    hook_cmd=$(get_hook_command "$project_dir" "$hook_name")
    
    if [[ -z "$hook_cmd" ]]; then
        log_debug "No $hook_name hook defined"
        return 0
    fi
    
    log_info "Executing $hook_name hook: $hook_cmd"
    
    cd "$project_dir" || return 1
    
    if eval "$hook_cmd"; then
        log_success "$hook_name hook completed successfully"
        return 0
    else
        log_error "$hook_name hook failed"
        return 1
    fi
}

#######################################
# Aliases
#######################################

# Get project aliases
# Arguments:
#   $1 - Project directory path
# Returns:
#   JSON object of aliases
get_project_aliases() {
    local project_dir="$1"
    local config_file="$project_dir/$BOOTSTRAP_CONFIG_FILE"
    
    if [[ ! -f "$config_file" ]]; then
        echo "{}"
        return 0
    fi
    
    jq -r '.aliases // {}' "$config_file" 2>/dev/null || echo "{}"
}

#######################################
# Export functions
#######################################

export -f detect_project_type
export -f read_bootstrap_config
export -f validate_bootstrap_config
export -f get_config_value
export -f get_config_array
export -f get_required_dependencies
export -f get_runtime_dependencies
export -f get_optional_dependencies
export -f get_required_databases
export -f get_required_cache
export -f get_required_queues
export -f get_secrets_vault
export -f get_required_secrets
export -f get_optional_secrets
export -f get_hook_command
export -f execute_hook
export -f get_project_aliases

log_debug "detect.sh loaded successfully"
