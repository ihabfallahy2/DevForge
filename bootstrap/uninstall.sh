#!/bin/bash

#######################################
# Universal Project Bootstrapper - Uninstaller
# Removes the bootstrapper from the system
#######################################

set -euo pipefail

# Installation directories
INSTALL_DIR="/usr/local/bin"
LIB_INSTALL_DIR="/usr/local/lib/bootstrap"
TEMPLATES_INSTALL_DIR="/usr/local/share/bootstrap"
DOCS_INSTALL_DIR="/usr/local/share/bootstrap"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    log_error "This uninstaller must be run as root (use sudo)"
    exit 1
fi

# Confirmation
echo -e "${YELLOW}WARNING: This will remove the Universal Project Bootstrapper from your system.${NC}"
echo -e "This will NOT remove projects that were bootstrapped."
echo ""
read -p "Are you sure you want to continue? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy]es$ ]]; then
    log_info "Uninstallation cancelled"
    exit 0
fi

log_info "Uninstalling Universal Project Bootstrapper..."

# Remove main executable
if [[ -f "$INSTALL_DIR/bootstrap" ]]; then
    log_info "Removing $INSTALL_DIR/bootstrap..."
    rm -f "$INSTALL_DIR/bootstrap"
fi

# Remove libraries
if [[ -d "$LIB_INSTALL_DIR" ]]; then
    log_info "Removing $LIB_INSTALL_DIR..."
    rm -rf "$LIB_INSTALL_DIR"
fi

# Remove templates and docs
if [[ -d "$TEMPLATES_INSTALL_DIR" ]]; then
    log_info "Removing $TEMPLATES_INSTALL_DIR..."
    rm -rf "$TEMPLATES_INSTALL_DIR"
fi

# Ask about removing aliases
echo ""
log_warn "Project aliases may still be in your shell configuration files."
echo "Aliases are in files like ~/.bashrc or ~/.zshrc with markers like:"
echo "  # BOOTSTRAP-ALIASES-START: project-name"
echo "  # BOOTSTRAP-ALIASES-END: project-name"
echo ""
read -p "Would you like to remove all bootstrap aliases? (yes/no): " -r
if [[ $REPLY =~ ^[Yy]es$ ]]; then
    # Remove from common shell configs
    for config_file in ~/.bashrc ~/.zshrc ~/.bash_profile; do
        if [[ -f "$config_file" ]]; then
            if grep -q "BOOTSTRAP-ALIASES" "$config_file"; then
                log_info "Removing aliases from $config_file..."
                # Create backup
                cp "$config_file" "${config_file}.backup.$(date +%Y%m%d_%H%M%S)"
                # Remove all bootstrap alias blocks
                sed -i '/# BOOTSTRAP-ALIASES-START:/,/# BOOTSTRAP-ALIASES-END:/d' "$config_file"
            fi
        fi
    done
    log_info "Shell configuration backups created with timestamp"
fi

log_success "Universal Project Bootstrapper has been uninstalled"
log_info ""
log_info "Note: If you had the shell open when aliases were removed,"
log_info "you may need to restart your terminal or run:"
log_info "  source ~/.bashrc  # or ~/.zshrc"
