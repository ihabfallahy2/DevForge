#!/bin/bash

#######################################
# Git Operations
# Handles repository cloning and configuration
#######################################

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/common.sh"

#######################################
# URL Parsing
#######################################

# Normalize repository URL
# Arguments:
#   $1 - Repository string (name, user/repo, or full URL)
# Returns:
#   Full HTTPS URL
normalize_repo_url() {
    local input="$1"
    
    # Check if it's already a URL
    if [[ "$input" =~ ^https?:// ]] || [[ "$input" =~ ^git@ ]]; then
        echo "$input"
        return 0
    fi
    
    # Check for gitlab: prefix
    if [[ "$input" =~ ^gitlab: ]]; then
        echo "https://gitlab.com/${input#gitlab:}.git"
        return 0
    fi
    
    # Check for bitbucket: prefix
    if [[ "$input" =~ ^bitbucket: ]]; then
        echo "https://bitbucket.org/${input#bitbucket:}.git"
        return 0
    fi
    
    # Default to GitHub
    # If just a name (e.g., "dynamoss"), assume user's repo (needs configuration or default user)
    # For now, if no user provided, we can't guess, so we assume it's a full user/repo string
    
    if [[ "$input" =~ / ]]; then
        echo "https://github.com/${input}.git"
    else
        # If just a name, try to find a default user from git config or env
        local user="${GITHUB_USER:-}"
        if [[ -z "$user" ]]; then
            # Try to get from git config
            user=$(git config --global github.user || echo "")
        fi
        
        if [[ -n "$user" ]]; then
            echo "https://github.com/${user}/${input}.git"
        else
            # Fallback: assume input is the full repo name if it contains no slash, 
            # but this is risky. Better to error or require user/repo.
            # For this bootstrapper, let's assume "ihabfallahy2" as default if configured,
            # otherwise require full path.
            # ACTUALLY, let's just return it as is and let git fail if invalid, 
            # or better, assume it's a shortcut for ihabfallahy2 (the user) as per the prompt example.
            echo "https://github.com/ihabfallahy2/${input}.git"
        fi
    fi
}

#######################################
# Repository Operations
#######################################

# Clone repository
# Arguments:
#   $1 - Repository URL or name
#   $2 - Target directory (optional)
#   $3 - Branch (optional)
# Returns:
#   0 if successful, 1 otherwise
clone_repository() {
    local repo_input="$1"
    local target_dir="${2:-}"
    local branch="${3:-}"
    
    local repo_url
    repo_url=$(normalize_repo_url "$repo_input")
    
    # Determine target directory if not provided
    if [[ -z "$target_dir" ]]; then
        # Extract repo name from URL
        target_dir=$(basename "$repo_url" .git)
    fi
    
    log_step "Cloning Repository"
    log_info "Repository: $repo_url"
    log_info "Destination: $target_dir"
    
    if [[ -d "$target_dir" ]]; then
        log_warn "Directory $target_dir already exists"
        if confirm "Overwrite existing directory?" "n"; then
            log_info "Removing existing directory..."
            rm -rf "$target_dir"
        else
            log_info "Using existing directory"
            # If using existing, make sure it's the right repo
            if [[ -d "$target_dir/.git" ]]; then
                (cd "$target_dir" && git remote get-url origin)
                return 0
            else
                log_error "Directory exists but is not a git repository"
                return 1
            fi
        fi
    fi
    
    local cmd="git clone"
    if [[ -n "$branch" ]]; then
        cmd="$cmd -b $branch"
    fi
    cmd="$cmd $repo_url $target_dir"
    
    if run_with_retry "$cmd"; then
        log_success "Repository cloned successfully"
        return 0
    else
        log_error "Failed to clone repository"
        return 1
    fi
}

# Checkout branch
# Arguments:
#   $1 - Directory
#   $2 - Branch name
checkout_branch() {
    local dir="$1"
    local branch="$2"
    
    if [[ -z "$branch" ]]; then
        return 0
    fi
    
    log_info "Checking out branch: $branch"
    
    cd "$dir" || return 1
    
    if git checkout "$branch"; then
        log_success "Switched to branch $branch"
        
        # Pull latest changes
        log_info "Pulling latest changes..."
        git pull origin "$branch"
        return 0
    else
        log_error "Failed to checkout branch $branch"
        return 1
    fi
}

#######################################
# Git Hooks
#######################################

# Setup git hooks
# Arguments:
#   $1 - Project directory
setup_git_hooks() {
    local project_dir="$1"
    
    log_debug "Setting up git hooks for $project_dir"
    
    # Only relevant for server-side bare repos usually, but for auto-deploy
    # we might want to setup a post-merge hook if we pull on the server.
    # Or if we are setting up a bare repo to push to.
    
    # For this bootstrapper, we are likely setting up a working directory.
    # So maybe we want to setup a 'post-merge' hook to restart app on pull?
    
    local hooks_dir="$project_dir/.git/hooks"
    
    if [[ ! -d "$hooks_dir" ]]; then
        log_warn "No hooks directory found (is this a git repo?)"
        return 1
    fi
    
    # Example: Create a post-merge hook that calls the deploy script
    # This is useful if someone runs 'git pull' manually or via webhook
    
    local hook_file="$hooks_dir/post-merge"
    
    cat > "$hook_file" << 'EOF'
#!/bin/bash
echo "🔄 Changes detected (post-merge)"
# Check if deploy script exists
if [[ -f "./deploy.sh" ]]; then
    echo "🚀 Triggering deployment..."
    ./deploy.sh
fi
EOF
    
    chmod +x "$hook_file"
    log_success "Git hooks configured"
}

export -f normalize_repo_url
export -f clone_repository
export -f checkout_branch
export -f setup_git_hooks

log_debug "git.sh loaded successfully"
