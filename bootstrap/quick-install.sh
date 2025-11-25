#!/bin/bash

#######################################
# Universal Bootstrapper - Remote Installer
# Can be executed via: curl -sSL URL | bash -s PROJECT
#######################################

set -euo pipefail

# Configuration
REPO_URL="${BOOTSTRAP_REPO_URL:-https://github.com/ihabfallahy2/bootstrap}"
BRANCH="${BOOTSTRAP_BRANCH:-main}"
INSTALL_DIR="/usr/local/bin"
LIB_DIR="/usr/local/lib/bootstrap"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Parse arguments
PROJECT_NAME="$1"
shift || true
BOOTSTRAP_ARGS="$@"

echo ""
echo "========================================="
echo "  Universal Project Bootstrapper"
echo "  One-command deployment solution"
echo "========================================="
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run with sudo"
    echo ""
    echo "Usage:"
    echo "  curl -sSL URL | sudo bash -s PROJECT_NAME [OPTIONS]"
    echo ""
    echo "Example:"
    echo "  curl -sSL https://raw.githubusercontent.com/USER/bootstrap/main/quick-install.sh | sudo bash -s dynamoss --env=prod"
    exit 1
fi

# Install prerequisites
log_info "Installing prerequisites..."
if command -v apt-get &> /dev/null; then
    apt-get update -qq
    apt-get install -y -qq curl git jq > /dev/null 2>&1
elif command -v dnf &> /dev/null; then
    dnf install -y -q curl git jq > /dev/null 2>&1
elif command -v yum &> /dev/null; then
    yum install -y -q curl git jq > /dev/null 2>&1
else
    log_error "Unsupported package manager"
    exit 1
fi

log_success "Prerequisites installed"

# Check if bootstrapper is already installed
if command -v bootstrap &> /dev/null; then
    log_info "Bootstrapper already installed, checking for updates..."
    
    # Check if update script exists
    if [[ -f "${LIB_DIR}/../update.sh" ]]; then
        log_info "Updating bootstrapper..."
        bash "${LIB_DIR}/../update.sh" > /dev/null 2>&1 || log_warn "Update failed, using existing version"
    fi
else
    log_info "Installing Universal Bootstrapper..."
    
    # Create temp directory
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # Download bootstrapper
    log_info "Downloading from ${REPO_URL}..."
    if ! git clone --depth 1 --branch "$BRANCH" "$REPO_URL" bootstrap > /dev/null 2>&1; then
        log_error "Failed to download bootstrapper"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
    
    cd bootstrap
    
    # Install
    log_info "Installing to system..."
    
    # Create directories
    mkdir -p "$LIB_DIR"
    mkdir -p "/usr/local/share/bootstrap/templates"
    mkdir -p "/usr/local/share/bootstrap/docs"
    
    # Copy files
    cp bootstrap.sh "$INSTALL_DIR/bootstrap"
    chmod +x "$INSTALL_DIR/bootstrap"
    
    cp -r lib/* "$LIB_DIR/"
    cp -r templates/* "/usr/local/share/bootstrap/templates/" 2>/dev/null || true
    cp -r docs/* "/usr/local/share/bootstrap/docs/" 2>/dev/null || true
    
    # Update paths in bootstrap.sh
    sed -i "s|LIB_DIR=\"\${SCRIPT_DIR}/lib\"|LIB_DIR=\"$LIB_DIR\"|" "$INSTALL_DIR/bootstrap"
    
    # Cleanup
    cd /
    rm -rf "$TEMP_DIR"
    
    log_success "Bootstrapper installed successfully!"
fi

# Verify installation
if ! command -v bootstrap &> /dev/null; then
    log_error "Installation verification failed"
    exit 1
fi

echo ""
log_success "Installation complete!"

# If project name provided, bootstrap it
if [[ -n "$PROJECT_NAME" ]]; then
    echo ""
    log_info "Bootstrapping project: $PROJECT_NAME"
    log_info "Additional arguments: $BOOTSTRAP_ARGS"
    echo ""
    
    # Execute bootstrap
    # shellcheck disable=SC2086
    bootstrap "$PROJECT_NAME" $BOOTSTRAP_ARGS
    
    BOOTSTRAP_EXIT=$?
    
    if [[ $BOOTSTRAP_EXIT -eq 0 ]]; then
        echo ""
        log_success "Project $PROJECT_NAME bootstrapped successfully!"
        echo ""
        echo "To use the configured aliases, run:"
        echo "  source ~/.bashrc  # or ~/.zshrc"
    else
        echo ""
        log_error "Bootstrap failed with exit code $BOOTSTRAP_EXIT"
        exit $BOOTSTRAP_EXIT
    fi
else
    echo ""
    log_info "Bootstrapper installed. Usage:"
    echo ""
    echo "  bootstrap PROJECT_NAME [OPTIONS]"
    echo ""
    echo "Examples:"
    echo "  bootstrap dynamoss --env=prod"
    echo "  bootstrap my-app --vault=my-vault"
    echo ""
    echo "For help:"
    echo "  bootstrap --help"
fi

echo ""
log_success "All done! 🚀"
echo ""
