#!/bin/bash

#######################################
# Secret Management
# Handles 1Password integration and .env generation
#######################################

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/common.sh"

#######################################
# 1Password Integration
#######################################

# Check 1Password authentication status
# Returns:
#   0 if authenticated, 1 otherwise
check_1password_auth() {
    if ! check_command op; then
        log_debug "1Password CLI not installed"
        return 1
    fi
    
    if op account list >/dev/null 2>&1; then
        log_debug "1Password authenticated"
        return 0
    else
        log_debug "1Password not authenticated"
        return 1
    fi
}

# Authenticate with 1Password
# Returns:
#   0 if successful, 1 otherwise
authenticate_1password() {
    if check_1password_auth; then
        return 0
    fi
    
    log_info "Authenticating with 1Password..."
    
    # Check if we have a service account token
    if [[ -n "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]]; then
        log_info "Using Service Account Token"
        return 0
    fi
    
    # Interactive login
    if eval "$(op signin)"; then
        log_success "Successfully authenticated with 1Password"
        return 0
    else
        log_error "Failed to authenticate with 1Password"
        return 1
    fi
}

# Read secrets from vault
# Arguments:
#   $1 - Vault name
# Returns:
#   JSON object with secrets
read_secrets_from_vault() {
    local vault="$1"
    
    if ! check_1password_auth; then
        log_error "Not authenticated with 1Password"
        return 1
    fi
    
    log_info "Reading secrets from vault: $vault"
    
    # List items in vault and format as JSON
    # We want to get all items and their fields
    # This might be slow for large vaults, so we might want to filter
    
    # Strategy:
    # 1. Get all items in vault
    # 2. For each item, get its fields
    # 3. Map to key-value pairs
    
    # Simplified approach: Assume items are named as the env var key
    # OR assume one item contains multiple fields
    
    # Let's try to find an item named "Env" or "Secrets" or the project name
    # If not found, list all items and treat titles as keys (if they look like env vars)
    
    # Better approach for "Universal" system:
    # Look for items where the title matches the variable name (e.g. MONGODB_URI)
    # OR look for an item named "Environment Variables" and read its fields
    
    # Let's try to get all items in the vault and map them
    # Output format: {"KEY": "VALUE", ...}
    
    if ! op item list --vault "$vault" --format=json >/dev/null 2>&1; then
        log_error "Vault '$vault' not found or empty"
        return 1
    fi
    
    # Get all items and extract their "password" or "credential" or "text" fields
    # This is complex to do generically.
    
    # Let's stick to the prompt's suggestion:
    # op item list --vault="dynamoss-prod" --format=json | \
    #   jq -r '.[] | "\(.title)=\(.fields[] | select(.label=="password").value)"'
    
    # But we want to be more robust.
    # We will fetch all items, and for each item:
    # - If title is UPPERCASE_WITH_UNDERSCORES, treat title as Key and value as Value
    # - If item has a field "value", use that. Else use "password".
    
    op item list --vault "$vault" --format json | \
    jq -r '.[] | .id' | \
    while read -r item_id; do
        op item get "$item_id" --format json | \
        jq -r '
            .title as $key |
            (.fields[] | select(.label == "password" or .label == "credential" or .label == "text" or .label == "value") | select(.value != null) | .value) as $val |
            "\($key)=\($val)"
        '
    done
}

#######################################
# Environment File Generation
#######################################

# Generate .env file
# Arguments:
#   $1 - Project directory
#   $2 - Vault name
#   $3 - Required secrets list (newline separated)
generate_env_file() {
    local project_dir="$1"
    local vault="$2"
    local required_secrets="$3"
    local env_file="$project_dir/.env"
    
    log_step "Configuring Secrets"
    
    # Backup existing .env
    backup_file "$env_file"
    
    # Start with empty file or copy example
    if [[ -f "$project_dir/.env.example" ]]; then
        cp "$project_dir/.env.example" "$env_file"
        log_debug "Initialized .env from .env.example"
    else
        touch "$env_file"
    fi
    
    # Try 1Password first
    local use_1password=false
    if check_command op && [[ -n "$vault" ]]; then
        if authenticate_1password; then
            use_1password=true
        else
            log_warn "Could not authenticate with 1Password, falling back to interactive mode"
        fi
    fi
    
    # Process required secrets
    local missing_secrets=()
    
    while IFS= read -r secret_name; do
        [[ -z "$secret_name" ]] && continue
        
        local value=""
        
        # 1. Try 1Password
        if [[ "$use_1password" == "true" ]]; then
            log_info "Fetching $secret_name from 1Password..."
            # Try to find item with exact title
            value=$(op item get "$secret_name" --vault "$vault" --fields password,credential,text,value 2>/dev/null || echo "")
            
            if [[ -z "$value" ]]; then
                # Try to find field within a "Secrets" item?
                # For now, just log warning
                log_warn "Secret $secret_name not found in vault $vault"
            else
                log_success "Found $secret_name in 1Password"
            fi
        fi
        
        # 2. If not found, check if already in .env (from example or previous run)
        if [[ -z "$value" ]]; then
            # Check if variable is set in current environment (e.g. CI/CD)
            if [[ -n "${!secret_name:-}" ]]; then
                value="${!secret_name}"
                log_info "Using environment variable for $secret_name"
            # Check if already in .env file with a value (not empty/comment)
            elif grep -q "^${secret_name}=" "$env_file"; then
                local current_val
                current_val=$(grep "^${secret_name}=" "$env_file" | cut -d= -f2-)
                if [[ -n "$current_val" ]]; then
                    log_info "Using existing value for $secret_name"
                    continue # Skip writing, already there
                fi
            fi
        fi
        
        # 3. Interactive fallback
        if [[ -z "$value" ]]; then
            if [[ "${NON_INTERACTIVE}" == "true" ]]; then
                log_error "Missing required secret: $secret_name"
                missing_secrets+=("$secret_name")
                continue
            fi
            
            echo -n "Enter value for $secret_name: "
            read -r -s value
            echo ""
        fi
        
        # Update .env file
        if [[ -n "$value" ]]; then
            # Escape value for sed
            local escaped_value
            escaped_value=$(printf '%s\n' "$value" | sed -e 's/[\/&]/\\&/g')
            
            if grep -q "^${secret_name}=" "$env_file"; then
                # Replace existing
                # Use a temporary file to avoid issues with sed in-place on some systems
                local temp_file="${env_file}.tmp"
                sed "s/^${secret_name}=.*/${secret_name}=${escaped_value}/" "$env_file" > "$temp_file"
                mv "$temp_file" "$env_file"
            else
                # Append
                echo "${secret_name}=${value}" >> "$env_file"
            fi
        else
            log_warn "No value provided for $secret_name"
            missing_secrets+=("$secret_name")
        fi
        
    done <<< "$required_secrets"
    
    # Set permissions
    chmod 600 "$env_file"
    
    if [[ ${#missing_secrets[@]} -gt 0 ]]; then
        log_error "Missing secrets: ${missing_secrets[*]}"
        return 1
    fi
    
    log_success "Secrets configured successfully in .env"
    return 0
}

export -f check_1password_auth
export -f authenticate_1password
export -f read_secrets_from_vault
export -f generate_env_file

log_debug "secrets.sh loaded successfully"
