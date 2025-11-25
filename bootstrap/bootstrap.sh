#!/bin/bash

#######################################
# Universal Project Bootstrapper
# Main Orchestrator Script
#######################################

# Set strict error handling
set -euo pipefail

# Directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"

# Load libraries
# shellcheck source=lib/common.sh
source "${LIB_DIR}/common.sh"
# shellcheck source=lib/detect.sh
source "${LIB_DIR}/detect.sh"
# shellcheck source=lib/install.sh
source "${LIB_DIR}/install.sh"
# shellcheck source=lib/git.sh
source "${LIB_DIR}/git.sh"
# shellcheck source=lib/secrets.sh
source "${LIB_DIR}/secrets.sh"
# shellcheck source=lib/aliases.sh
source "${LIB_DIR}/aliases.sh"
# shellcheck source=lib/discord.sh
source "${LIB_DIR}/discord.sh"

#######################################
# Global Variables
#######################################

PROJECT_NAME=""
REPO_URL=""
TARGET_DIR=""
ENVIRONMENT="prod"
VAULT=""
BRANCH=""
SKIP_DEPLOY=false
VERBOSE=false
NON_INTERACTIVE=false

#######################################
# Help Function
#######################################

show_help() {
    echo "Universal Project Bootstrapper"
    echo "Usage: ./bootstrap.sh [PROJECT_NAME] [OPTIONS]"
    echo ""
    echo "Arguments:"
    echo "  PROJECT_NAME          Name of the project or repository URL"
    echo ""
    echo "Options:"
    echo "  --env=ENV             Environment (prod, dev, staging) [default: prod]"
    echo "  --vault=NAME          1Password vault name"
    echo "  --dir=PATH            Target directory"
    echo "  --branch=NAME         Git branch to checkout"
    echo "  --skip-deploy         Skip deployment step"
    echo "  --non-interactive     Run without user prompts"
    echo "  --verbose             Enable verbose logging"
    echo "  --help                Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./bootstrap.sh dynamoss"
    echo "  ./bootstrap.sh dynamoss --env=dev --vault='dynamoss-dev'"
    echo "  ./bootstrap.sh https://github.com/user/repo --dir=/opt/my-app"
}

#######################################
# Argument Parsing
#######################################

parse_arguments() {
    # If no arguments, show help
    if [[ $# -eq 0 ]]; then
        show_help
        exit 1
    fi
    
    # First argument is project name if it doesn't start with -
    if [[ "$1" != -* ]]; then
        PROJECT_NAME="$1"
        shift
    fi
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --env=*)
                ENVIRONMENT="${1#*=}"
                shift
                ;;
            --vault=*)
                VAULT="${1#*=}"
                shift
                ;;
            --dir=*)
                TARGET_DIR="${1#*=}"
                shift
                ;;
            --branch=*)
                BRANCH="${1#*=}"
                shift
                ;;
            --skip-deploy)
                SKIP_DEPLOY=true
                shift
                ;;
            --non-interactive)
                NON_INTERACTIVE=true
                export NON_INTERACTIVE=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                export VERBOSE=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown argument: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    if [[ -z "$PROJECT_NAME" ]]; then
        log_error "Project name is required"
        show_help
        exit 1
    fi
}

#######################################
# Main Flow
#######################################

main() {
    setup_cleanup_trap
    
    log_step "Initializing Universal Bootstrapper"
    log_info "Project: $PROJECT_NAME"
    log_info "Environment: $ENVIRONMENT"
    
    # 1. Install Base Dependencies
    log_step "Checking System Dependencies"
    install_basic_tools
    
    # 2. Clone Repository
    if [[ -z "$TARGET_DIR" ]]; then
        # If project name is a URL, extract name
        if [[ "$PROJECT_NAME" =~ / ]]; then
            TARGET_DIR=$(basename "$PROJECT_NAME" .git)
        else
            TARGET_DIR="$PROJECT_NAME"
        fi
    fi
    
    # Resolve absolute path for TARGET_DIR
    TARGET_DIR=$(get_absolute_path "$TARGET_DIR")
    log_info "Target Directory: $TARGET_DIR"
    
    clone_repository "$PROJECT_NAME" "$TARGET_DIR" "$BRANCH"
    
    # Switch to project directory
    cd "$TARGET_DIR" || exit 1
    
    # 3. Detect Project Type & Config
    log_step "Analyzing Project"
    local project_type
    project_type=$(detect_project_type "$TARGET_DIR")
    log_info "Detected Type: $project_type"
    
    read_bootstrap_config "$TARGET_DIR" || log_warn "No project.bootstrap.json found, using defaults"
    
    # 4. Install Project Dependencies
    log_step "Installing Project Dependencies"
    local system_deps
    system_deps=$(get_required_dependencies "$TARGET_DIR")
    install_dependencies "$system_deps"
    
    local runtime_deps
    runtime_deps=$(get_runtime_dependencies "$TARGET_DIR")
    install_dependencies "$runtime_deps"
    
    # 5. Configure Secrets
    log_step "Configuring Secrets"
    local vault_name
    if [[ -n "$VAULT" ]]; then
        vault_name="$VAULT"
    else
        vault_name=$(get_secrets_vault "$TARGET_DIR" "$ENVIRONMENT")
    fi
    
    local required_secrets
    required_secrets=$(get_required_secrets "$TARGET_DIR")
    
    if [[ -n "$required_secrets" ]]; then
        generate_env_file "$TARGET_DIR" "$vault_name" "$required_secrets"
    else
        log_info "No required secrets defined"
    fi
    
    # 6. Setup Aliases
    log_step "Configuring Aliases"
    configure_aliases "$TARGET_DIR"
    
    # 7. Run Setup Hooks
    log_step "Running Setup Hooks"
    execute_hook "$TARGET_DIR" "post-clone"
    execute_hook "$TARGET_DIR" "post-secrets"
    
    # 8. Deploy
    if [[ "$SKIP_DEPLOY" == "false" ]]; then
        log_step "Deploying Application"
        
        # Get Discord Webhook URL if configured
        local discord_webhook=""
        # Try to get from env or config
        if [[ -n "${DISCORD_WEBHOOK_URL:-}" ]]; then
            discord_webhook="${DISCORD_WEBHOOK_URL}"
        else
            # Try to read from .env we just generated
            if grep -q "DISCORD_WEBHOOK_URL=" .env; then
                discord_webhook=$(grep "DISCORD_WEBHOOK_URL=" .env | cut -d= -f2-)
            fi
        fi
        
        if [[ -n "$discord_webhook" ]]; then
            notify_deploy_start "$discord_webhook" "$PROJECT_NAME" "$ENVIRONMENT" "${BRANCH:-main}"
        fi
        
        # Run pre-deploy hook
        execute_hook "$TARGET_DIR" "pre-deploy"
        
        # Execute deployment
        # Priority:
        # 1. 'deploy' alias command
        # 2. ./deploy.sh script
        # 3. docker-compose up -d
        
        local deploy_cmd=""
        local aliases_json
        aliases_json=$(get_project_aliases "$TARGET_DIR")
        local alias_deploy
        alias_deploy=$(echo "$aliases_json" | jq -r '.deploy // empty')
        
        if [[ -n "$alias_deploy" ]]; then
            deploy_cmd="$alias_deploy"
        elif [[ -f "./deploy.sh" ]]; then
            chmod +x ./deploy.sh
            deploy_cmd="./deploy.sh"
        elif [[ -f "docker-compose.yml" ]]; then
            deploy_cmd="docker-compose up -d --build"
        elif [[ -f "Makefile" ]] && grep -q "deploy:" Makefile; then
            deploy_cmd="make deploy"
        fi
        
        if [[ -n "$deploy_cmd" ]]; then
            log_info "Executing deploy command: $deploy_cmd"
            
            local start_time
            start_time=$(date +%s)
            
            if eval "$deploy_cmd"; then
                local end_time
                end_time=$(date +%s)
                local duration=$((end_time - start_time))
                
                log_success "Deployment successful!"
                execute_hook "$TARGET_DIR" "post-deploy"
                
                if [[ -n "$discord_webhook" ]]; then
                    notify_deploy_success "$discord_webhook" "$PROJECT_NAME" "$ENVIRONMENT" "${duration}s"
                fi
            else
                log_error "Deployment failed"
                if [[ -n "$discord_webhook" ]]; then
                    notify_deploy_failure "$discord_webhook" "$PROJECT_NAME" "$ENVIRONMENT" "Command failed: $deploy_cmd"
                fi
                exit 1
            fi
        else
            log_warn "No deployment method found (no deploy alias, deploy.sh, or docker-compose.yml)"
        fi
    else
        log_info "Skipping deployment as requested"
    fi
    
    log_step "Bootstrap Complete!"
    log_success "Project $PROJECT_NAME has been successfully bootstrapped."
    log_info "Location: $TARGET_DIR"
    log_info "To use aliases, run: source $(get_shell_config)"
}

# Parse arguments and run main
parse_arguments "$@"
main
