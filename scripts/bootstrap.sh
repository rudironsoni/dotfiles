#!/usr/bin/env bash
# ==============================================================================
# Dotfiles Bootstrap Script
# ==============================================================================
# Managed by chezmoi: https://chezmoi.io/
# This script installs chezmoi, 1Password CLI, and applies dotfiles
#
# Usage:
#   ./scripts/bootstrap.sh [--force] [--dry-run] [--backup]
#
# Options:
#   --force      Apply without prompting
#   --dry-run    Show what would be done without doing it
#   --backup     Create backup of existing dotfiles before applying
#
# ==============================================================================

set -euo pipefail

# Configuration
REPO="rudironsoni"
CHEZMOI_SOURCE="https://github.com/${REPO}/dotfiles.git"
BACKUP_DIR="${HOME}/.dotfiles.backup.$(date +%Y%m%d_%H%M%S)"

# Parse arguments
FORCE=false
DRY_RUN=false
DO_BACKUP=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --backup)
            DO_BACKUP=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Linux*)
            echo "linux"
            ;;
        Darwin*)
            echo "darwin"
            ;;
        CYGWIN*|MINGW*|MSYS*)
            echo "windows"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Detect package manager
detect_package_manager() {
    local os=$1
    
    if [ "$os" = "darwin" ]; then
        if command -v brew &> /dev/null; then
            echo "brew"
        fi
    elif [ "$os" = "linux" ]; then
        if command -v brew &> /dev/null; then
            echo "brew"
        elif command -v apt-get &> /dev/null; then
            echo "apt"
        elif command -v dnf &> /dev/null; then
            echo "dnf"
        elif command -v pacman &> /dev/null; then
            echo "pacman"
        elif command -v zypper &> /dev/null; then
            echo "zypper"
        fi
    elif [ "$os" = "windows" ]; then
        if command -v winget &> /dev/null; then
            echo "winget"
        elif command -v choco &> /dev/null; then
            echo "choco"
        fi
    fi
}

# Install chezmoi
install_chezmoi() {
    local os=$1
    local pkg_manager=$2
    
    if command -v chezmoi &> /dev/null; then
        log_info "chezmoi already installed: $(chezmoi --version)"
        return 0
    fi
    
    log_info "Installing chezmoi..."
    
    case "$pkg_manager" in
        brew)
            brew install chezmoi
            ;;
        apt)
            # Add chezmoi repository or use install script
            sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "${HOME}/.local/bin"
            ;;
        dnf)
            sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "${HOME}/.local/bin"
            ;;
        pacman)
            sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "${HOME}/.local/bin"
            ;;
        winget)
            winget install --id twpayne.chezmoi -e --accept-source-agreements --accept-package-agreements
            ;;
        choco)
            choco install chezmoi -y
            ;;
        *)
            # Fallback to install script
            sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "${HOME}/.local/bin"
            ;;
    esac
    
    log_success "chezmoi installed"
}

# Install 1Password CLI
install_1password() {
    local os=$1
    local pkg_manager=$2
    
    if command -v op &> /dev/null; then
        log_info "1Password CLI already installed: $(op --version)"
        return 0
    fi
    
    log_info "Installing 1Password CLI..."
    
    case "$pkg_manager" in
        brew)
            brew install 1password-cli
            ;;
        apt)
            # Add 1Password repository
            curl -sS https://downloads.1password.com/linux/keys/1password.asc | gpg --dearmor > /tmp/1password.gpg
            echo "deb [arch=amd64] https://downloads.1password.com/linux/debian stable main" | tee /etc/apt/sources.list.d/1password.list
            apt-get update && apt-get install -y 1password-cli
            ;;
        dnf)
            rpm --import https://downloads.1password.com/linux/keys/1password.asc
            cat > /etc/yum.repos.d/1password.repo << EOF
[1Password]
baseurl=https://downloads.1password.com/linux/rpm/
enabled=1
gpgcheck=1
gpgkey=https://downloads.1password.com/linux/keys/1password.asc
EOF
            dnf install -y 1password-cli
            ;;
        winget)
            winget install --id AgileBits.1Password -e --accept-source-agreements --accept-package-agreements
            ;;
        choco)
            choco install 1password-cli -y
            ;;
        *)
            log_warning "Cannot install 1Password CLI automatically for this OS"
            log_info "Please install manually: https://developer.1password.com/docs/cli/install"
            return 1
            ;;
    esac
    
    log_success "1Password CLI installed"
}

# Backup existing dotfiles
backup_dotfiles() {
    if [ "$DO_BACKUP" = false ]; then
        return 0
    fi
    
    log_info "Creating backup at ${BACKUP_DIR}"
    
    # Create backup directory
    mkdir -p "${BACKUP_DIR}"
    
    # Files to backup
    local files=(
        ".bashrc"
        ".zshrc"
        ".profile"
        ".gitconfig"
        ".gitignore_global"
    )
    
    for file in "${files[@]}"; do
        if [ -f "${HOME}/${file}" ]; then
            cp -r "${HOME}/${file}" "${BACKUP_DIR}/"
            log_info "Backed up ${file}"
        fi
    done
    
    # Backup .config directory
    if [ -d "${HOME}/.config" ]; then
        cp -r "${HOME}/.config" "${BACKUP_DIR}/"
        log_info "Backed up .config/"
    fi
    
    # Backup .ssh directory
    if [ -d "${HOME}/.ssh" ]; then
        cp -r "${HOME}/.ssh" "${BACKUP_DIR}/"
        log_info "Backed up .ssh/"
    fi
    
    log_success "Backup complete at ${BACKUP_DIR}"
}

# Initialize chezmoi
init_chezmoi() {
    log_info "Initializing chezmoi from ${REPO}/dotfiles..."
    
    if [ "$DRY_RUN" = true ]; then
        log_info "DRY RUN: Would run: chezmoi init ${REPO} --apply=${FORCE}"
        return 0
    fi
    
    # Check if already initialized
    if [ -d "${HOME}/.local/share/chezmoi" ]; then
        log_info "chezmoi already initialized, updating..."
        cd "${HOME}/.local/share/chezmoi"
        git pull origin main
        cd -
    else
        chezmoi init "${REPO}"
    fi
    
    log_success "chezmoi initialized"
}

# Apply dotfiles
apply_dotfiles() {
    log_info "Applying dotfiles..."
    
    if [ "$DRY_RUN" = true ]; then
        log_info "DRY RUN: Would run: chezmoi apply --force=${FORCE}"
        chezmoi apply --dry-run --verbose
        return 0
    fi
    
    if [ "$FORCE" = true ]; then
        chezmoi apply --force --verbose
    else
        chezmoi apply --verbose
    fi
    
    log_success "Dotfiles applied"
}

# Main function
main() {
    local os
    local pkg_manager
    
    echo "=========================================="
    echo "  Dotfiles Bootstrap Script"
    echo "=========================================="
    echo ""
    
    # Detect OS
    os=$(detect_os)
    log_info "Detected OS: ${os}"
    
    # Detect package manager
    pkg_manager=$(detect_package_manager "$os")
    if [ -z "$pkg_manager" ]; then
        log_warning "Could not detect package manager, will use fallback"
    else
        log_info "Detected package manager: ${pkg_manager}"
    fi
    
    echo ""
    
    # Prompt for confirmation (unless force)
    if [ "$FORCE" = false ] && [ "$DRY_RUN" = false ]; then
        read -p "Continue with bootstrap? [y/N] " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Aborted"
            exit 0
        fi
    fi
    
    echo ""
    
    # Backup (if requested)
    backup_dotfiles
    
    # Install chezmoi
    install_chezmoi "$os" "$pkg_manager"
    
    # Install 1Password CLI (optional)
    install_1password "$os" "$pkg_manager" || true
    
    echo ""
    
    # Initialize chezmoi
    init_chezmoi
    
    # Apply dotfiles
    apply_dotfiles
    
    echo ""
    echo "=========================================="
    log_success "Bootstrap complete!"
    echo "=========================================="
    echo ""
    echo "Next steps:"
    echo "  1. Sign in to 1Password: eval \$(op signin)"
    echo "  2. Review your dotfiles: chezmoi edit"
    echo "  3. Apply changes: chezmoi apply"
    echo ""
}

# Run main
main
