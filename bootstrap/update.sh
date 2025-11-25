#!/bin/bash

#######################################
# Universal Project Bootstrapper - Updater
# Updates the bootstrapper to the latest version
#######################################

set -euo pipefail

# Installation directory
INSTALL_DIR="/usr/local/bin"
LIB_INSTALL_DIR="/usr/local/lib/bootstrap"
TEMPLATES_INSTALL_DIR="/usr/local/share/bootstrap/templates"
DOCS_INSTALL_DIR="/usr/local/share/bootstrap/docs"

# Source URL
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
    log_error "This updater must be run as root (use sudo)"
    exit 1
fi

# Check if bootstrapper is installed
if [[ ! -f "$INSTALL_DIR/bootstrap" ]]; then
    log_error "Bootstrapper is not installed. Run install.sh first."
    exit 1
fi

log_info "Updating Universal Project Bootstrapper..."

# Backup current version
BACKUP_DIR="/tmp/bootstrap_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

log_info "Creating backup at $BACKUP_DIR..."
cp "$INSTALL_DIR/bootstrap" "$BACKUP_DIR/"
cp -r "$LIB_INSTALL_DIR" "$BACKUP_DIR/lib" 2>/dev/null || true

# Download latest version
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

log_info "Downloading latest version from $REPO_URL..."
if ! git clone --depth 1 --branch "$BRANCH" "$REPO_URL" bootstrap; then
    log_error "Failed to download update"
    rm -rf "$TEMP_DIR"
    exit 1
fi

cd bootstrap

# Install new version
log_info "Installing update..."
cp bootstrap.sh "$INSTALL_DIR/bootstrap"
chmod +x "$INSTALL_DIR/bootstrap"

cp -r lib/* "$LIB_INSTALL_DIR/"
cp -r templates/* "$TEMPLATES_INSTALL_DIR/"
cp -r docs/* "$DOCS_INSTALL_DIR/"

# Update paths
sed -i "s|LIB_DIR=\"\${SCRIPT_DIR}/lib\"|LIB_DIR=\"$LIB_INSTALL_DIR\"|" "$INSTALL_DIR/bootstrap"

# Cleanup
cd /
rm -rf "$TEMP_DIR"

log_success "Universal Project Bootstrapper updated successfully!"
log_info "Backup available at: $BACKUP_DIR"
log_info ""
log_info "To restore the backup if needed:"
log_info "  sudo cp $BACKUP_DIR/bootstrap $INSTALL_DIR/"
