#!/bin/bash

#######################################
# Universal Project Bootstrapper - Installer
# Installs the bootstrapper on the system
#######################################

set -euo pipefail

# Installation directory
INSTALL_DIR="/usr/local/bin"
LIB_INSTALL_DIR="/usr/local/lib/bootstrap"
TEMPLATES_INSTALL_DIR="/usr/local/share/bootstrap/templates"
DOCS_INSTALL_DIR="/usr/local/share/bootstrap/docs"

# Source URL (for remote installation)
REPO_URL="${BOOTSTRAP_REPO_URL:-https://github.com/ihabfallahy2/bootstrap}"
BRANCH="${BOOTSTRAP_BRANCH:-main}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
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

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    log_error "This installer must be run as root (use sudo)"
    exit 1
fi

log_info "Installing Universal Project Bootstrapper..."

# Check prerequisites
if ! command -v git &> /dev/null; then
    log_info "Installing git..."
    if command -v apt-get &> /dev/null; then
        apt-get update && apt-get install -y git
    elif command -v dnf &> /dev/null; then
        dnf install -y git
    else
        log_error "Cannot install git automatically. Please install git manually."
        exit 1
    fi
fi

# Create directories
log_info "Creating installation directories..."
mkdir -p "$LIB_INSTALL_DIR"
mkdir -p "$TEMPLATES_INSTALL_DIR"
mkdir -p "$DOCS_INSTALL_DIR"

# Clone or copy files
if [[ -f "./bootstrap.sh" ]]; then
    # Local installation
    log_info "Installing from local directory..."
    
    cp bootstrap.sh "$INSTALL_DIR/bootstrap"
    chmod +x "$INSTALL_DIR/bootstrap"
    
    cp -r lib/* "$LIB_INSTALL_DIR/"
    cp -r templates/* "$TEMPLATES_INSTALL_DIR/"
    cp -r docs/* "$DOCS_INSTALL_DIR/"
    
else
    # Remote installation
    log_info "Downloading from repository..."
    
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    if ! git clone --depth 1 --branch "$BRANCH" "$REPO_URL" bootstrap; then
        log_error "Failed to clone repository"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
    
    cd bootstrap
    
    cp bootstrap.sh "$INSTALL_DIR/bootstrap"
    chmod +x "$INSTALL_DIR/bootstrap"
    
    cp -r lib/* "$LIB_INSTALL_DIR/"
    cp -r templates/* "$TEMPLATES_INSTALL_DIR/"
    cp -r docs/* "$DOCS_INSTALL_DIR/"
    
    cd /
    rm -rf "$TEMP_DIR"
fi

# Update paths in bootstrap.sh to point to installed locations
sed -i "s|LIB_DIR=\"\${SCRIPT_DIR}/lib\"|LIB_DIR=\"$LIB_INSTALL_DIR\"|" "$INSTALL_DIR/bootstrap"

log_success "Universal Project Bootstrapper installed successfully!"
log_info "Location: $INSTALL_DIR/bootstrap"
log_info ""
log_info "Usage: bootstrap PROJECT_NAME [OPTIONS]"
log_info "Example: bootstrap dynamoss --env=prod"
log_info ""
log_info "For full documentation, visit: $DOCS_INSTALL_DIR"
log_info "Or run: bootstrap --help"
