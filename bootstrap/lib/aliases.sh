#!/bin/bash

#######################################
# Shell Aliases
# Manages global shell aliases for projects
#######################################

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/common.sh"

#######################################
# Alias Management
#######################################

# Configure aliases for a project
# Arguments:
#   $1 - Project directory
#   $2 - JSON string of aliases (optional)
configure_aliases() {
    local project_dir="$1"
    local aliases_json="${2:-}"
    
    log_step "Configuring Aliases"
    
    # If no aliases provided, try to read from config
    if [[ -z "$aliases_json" ]]; then
        # Need detect.sh functions
        if [[ -f "${SCRIPT_DIR}/detect.sh" ]]; then
            # shellcheck source=lib/detect.sh
            source "${SCRIPT_DIR}/detect.sh"
            aliases_json=$(get_project_aliases "$project_dir")
        else
            log_warn "detect.sh not found, cannot read project aliases"
            return 1
        fi
    fi
    
    if [[ -z "$aliases_json" || "$aliases_json" == "{}" || "$aliases_json" == "null" ]]; then
        log_info "No aliases defined for this project"
        return 0
    fi
    
    local shell_config
    shell_config=$(get_shell_config)
    
    log_info "Adding aliases to $shell_config"
    
    # Create a marker for this project's aliases
    local project_name
    project_name=$(basename "$project_dir")
    local start_marker="# BOOTSTRAP-ALIASES-START: $project_name"
    local end_marker="# BOOTSTRAP-ALIASES-END: $project_name"
    
    # Prepare new aliases content
    local new_content=""
    new_content+="$start_marker"$'\n'
    
    # Parse JSON and create alias commands
    # We need to handle the JSON parsing carefully
    
    # jq iteration
    while read -r key value; do
        # Skip if empty
        [[ -z "$key" ]] && continue
        
        # Format: alias key="cd project_dir && value"
        # We need to ensure the command runs in the project directory
        # But wait, the prompt says: "deploy": "cd ~/projects/dynamoss && make deploy"
        # If the user provided command already has cd, we use it as is.
        # If not, we prepend cd.
        
        local cmd="$value"
        if [[ "$cmd" != *"cd "* ]]; then
            cmd="cd $project_dir && $cmd"
        fi
        
        new_content+="alias $key='$cmd'"$'\n'
        log_info "Added alias: $key -> $cmd"
        
    done < <(echo "$aliases_json" | jq -r 'to_entries | .[] | "\(.key) \(.value)"')
    
    new_content+="$end_marker"$'\n'
    
    # Remove existing block if present
    if grep -q "$start_marker" "$shell_config"; then
        log_debug "Removing existing aliases for $project_name"
        # Use sed to delete the block
        # This is tricky with sed, so we might use a temporary file approach
        
        local temp_config="${shell_config}.tmp"
        sed "/$start_marker/,/$end_marker/d" "$shell_config" > "$temp_config"
        mv "$temp_config" "$shell_config"
    fi
    
    # Append new block
    echo -e "$new_content" >> "$shell_config"
    
    log_success "Aliases configured successfully"
    log_info "Please run: source $shell_config"
}

# Remove aliases for a project
# Arguments:
#   $1 - Project name
remove_aliases() {
    local project_name="$1"
    local shell_config
    shell_config=$(get_shell_config)
    
    local start_marker="# BOOTSTRAP-ALIASES-START: $project_name"
    local end_marker="# BOOTSTRAP-ALIASES-END: $project_name"
    
    if grep -q "$start_marker" "$shell_config"; then
        log_info "Removing aliases for $project_name from $shell_config"
        local temp_config="${shell_config}.tmp"
        sed "/$start_marker/,/$end_marker/d" "$shell_config" > "$temp_config"
        mv "$temp_config" "$shell_config"
        log_success "Aliases removed"
    else
        log_info "No aliases found for $project_name"
    fi
}

export -f configure_aliases
export -f remove_aliases

log_debug "aliases.sh loaded successfully"
