#!/bin/bash

#######################################
# Dependency Installation
# Installs system and runtime dependencies
#######################################

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/common.sh"

#######################################
# System Dependencies
#######################################

# Update package lists
update_packages() {
    log_info "Updating package lists..."
    
    if check_command apt-get; then
        run_with_retry "apt-get update -y"
    elif check_command dnf; then
        run_with_retry "dnf check-update" || true # dnf returns 100 if updates available
    elif check_command yum; then
        run_with_retry "yum check-update" || true
    else
        log_warn "Unknown package manager, skipping update"
    fi
}

# Install basic system tools
install_basic_tools() {
    log_info "Installing basic system tools..."
    
    local packages="curl wget git jq unzip tar make"
    
    if check_command apt-get; then
        # shellcheck disable=SC2086
        run_with_retry "apt-get install -y $packages"
    elif check_command dnf; then
        # shellcheck disable=SC2086
        run_with_retry "dnf install -y $packages"
    elif check_command yum; then
        # shellcheck disable=SC2086
        run_with_retry "yum install -y $packages"
    else
        log_warn "Cannot install basic tools: unknown package manager"
        return 1
    fi
    
    log_success "Basic tools installed"
}

#######################################
# Docker Installation
#######################################

# Install Docker and Docker Compose
install_docker() {
    if check_command docker; then
        log_info "Docker is already installed"
        return 0
    fi
    
    log_info "Installing Docker..."
    
    # Use official get-docker script
    if ! curl -fsSL https://get.docker.com -o get-docker.sh; then
        log_error "Failed to download Docker install script"
        return 1
    fi
    
    if ! sh get-docker.sh; then
        log_error "Failed to install Docker"
        rm get-docker.sh
        return 1
    fi
    rm get-docker.sh
    
    # Start Docker service
    if check_command systemctl; then
        systemctl start docker
        systemctl enable docker
    fi
    
    # Add current user to docker group if not root
    if ! is_root; then
        local user
        user=$(whoami)
        log_info "Adding user $user to docker group"
        sudo usermod -aG docker "$user"
    fi
    
    log_success "Docker installed successfully"
}

#######################################
# 1Password CLI Installation
#######################################

# Install 1Password CLI
install_1password_cli() {
    if check_command op; then
        log_info "1Password CLI is already installed"
        return 0
    fi
    
    log_info "Installing 1Password CLI..."
    
    local os
    os=$(detect_os)
    
    if [[ "$os" == "ubuntu" || "$os" == "debian" ]]; then
        # Install key and repository
        curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
            gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
            
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | \
            tee /etc/apt/sources.list.d/1password.list
            
        mkdir -p /etc/debsig/policies/AC2D62742012EA22/
        curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | \
            tee /etc/debsig/policies/AC2D62742012EA22/1password.pol
            
        mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
        curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
            gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg
            
        apt-get update && apt-get install -y 1password-cli
        
    elif [[ "$os" == "centos" || "$os" == "fedora" || "$os" == "rhel" ]]; then
        rpm --import https://downloads.1password.com/linux/keys/1password.asc
        sh -c 'echo -e "[1password]\nname=1Password Stable Channel\nbaseurl=https://downloads.1password.com/linux/rpm/stable/\$basearch\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=\"https://downloads.1password.com/linux/keys/1password.asc\"" > /etc/yum.repos.d/1password.repo'
        dnf install -y 1password-cli
        
    else
        # Fallback to binary download
        log_warn "Unsupported OS for package manager, trying binary download..."
        local arch
        arch=$(uname -m)
        case "$arch" in
            x86_64) arch="amd64" ;;
            aarch64) arch="arm64" ;;
        esac
        
        local url="https://cache.agilebits.com/dist/1P/op2/pkg/v2.23.0/op_linux_${arch}_v2.23.0.zip"
        download_file "$url" "op.zip"
        unzip op.zip
        mv op /usr/local/bin/
        rm op.zip op.sig
    fi
    
    if check_command op; then
        log_success "1Password CLI installed successfully"
    else
        log_error "Failed to install 1Password CLI"
        return 1
    fi
}

#######################################
# Runtime Installation
#######################################

# Install Java Runtime
# Arguments:
#   $1 - Version (e.g., "17", "21")
install_java() {
    local version="${1:-17}"
    
    if check_command java; then
        local current_version
        current_version=$(java -version 2>&1 | head -n 1 | awk -F '"' '{print $2}' | cut -d. -f1)
        if [[ "$current_version" == "$version" ]]; then
            log_info "Java $version is already installed"
            return 0
        fi
    fi
    
    log_info "Installing Java $version..."
    
    if check_command apt-get; then
        run_with_retry "apt-get install -y openjdk-${version}-jdk"
    elif check_command dnf; then
        run_with_retry "dnf install -y java-${version}-openjdk-devel"
    else
        log_warn "Cannot install Java: unknown package manager"
        return 1
    fi
    
    log_success "Java $version installed"
}

# Install Node.js
# Arguments:
#   $1 - Version (e.g., "18", "20")
install_nodejs() {
    local version="${1:-18}"
    
    if check_command node; then
        local current_version
        current_version=$(node -v | cut -d. -f1 | tr -d 'v')
        if [[ "$current_version" == "$version" ]]; then
            log_info "Node.js $version is already installed"
            return 0
        fi
    fi
    
    log_info "Installing Node.js $version..."
    
    if ! curl -fsSL "https://deb.nodesource.com/setup_${version}.x" | bash -; then
        log_error "Failed to setup Node.js repository"
        return 1
    fi
    
    if check_command apt-get; then
        run_with_retry "apt-get install -y nodejs"
    elif check_command dnf; then
        run_with_retry "dnf install -y nodejs"
    fi
    
    log_success "Node.js $version installed"
}

# Install Python
# Arguments:
#   $1 - Version (e.g., "3.11")
install_python() {
    local version="${1:-3.11}"
    
    if check_command python3; then
        local current_version
        current_version=$(python3 --version | awk '{print $2}' | cut -d. -f1,2)
        if [[ "$current_version" == "$version" ]]; then
            log_info "Python $version is already installed"
            return 0
        fi
    fi
    
    log_info "Installing Python $version..."
    
    if check_command apt-get; then
        run_with_retry "apt-get install -y python${version} python3-pip python3-venv"
    elif check_command dnf; then
        run_with_retry "dnf install -y python${version} python3-pip"
    fi
    
    log_success "Python $version installed"
}

#######################################
# Main Installation Function
#######################################

# Install dependencies based on list
# Arguments:
#   $1 - List of dependencies (newline separated)
install_dependencies() {
    local deps="$1"
    
    if [[ -z "$deps" ]]; then
        log_debug "No dependencies to install"
        return 0
    fi
    
    log_step "Installing Dependencies"
    
    # Ensure basic tools first
    install_basic_tools
    
    while IFS= read -r dep; do
        [[ -z "$dep" ]] && continue
        
        case "$dep" in
            docker)
                install_docker
                ;;
            docker-compose)
                # Included in modern docker installation
                if ! check_command docker-compose; then
                    log_info "Installing Docker Compose plugin..."
                    if check_command apt-get; then
                        run_with_retry "apt-get install -y docker-compose-plugin"
                    fi
                fi
                ;;
            1password-cli|op)
                install_1password_cli
                ;;
            java-*)
                local version=${dep#java-}
                install_java "$version"
                ;;
            node-*|nodejs-*)
                local version=${dep#node-}
                version=${version#js-}
                install_nodejs "$version"
                ;;
            python-*)
                local version=${dep#python-}
                install_python "$version"
                ;;
            git)
                # Already installed in basic tools
                ;;
            *)
                log_warn "Unknown dependency: $dep"
                ;;
        esac
    done <<< "$deps"
}

export -f update_packages
export -f install_basic_tools
export -f install_docker
export -f install_1password_cli
export -f install_java
export -f install_nodejs
export -f install_python
export -f install_dependencies

log_debug "install.sh loaded successfully"
