#!/usr/bin/env bash
# ==============================================================================
# Chezmoi Test Script
# ==============================================================================
# This script tests the dotfiles bootstrap in a Docker container
#
# ==============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS=0
FAIL=0

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASS++))
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAIL++))
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Test: Check chezmoi is installed
test_chezmoi_installed() {
    log_info "Testing: chezmoi is installed"
    
    if command -v chezmoi &> /dev/null; then
        local version
        version=$(chezmoi --version)
        log_success "chezmoi installed: ${version}"
    else
        log_error "chezmoi not found"
    fi
}

# Test: Check 1Password CLI is installed
test_1password_installed() {
    log_info "Testing: 1Password CLI is installed"
    
    if command -v op &> /dev/null; then
        local version
        version=$(op --version)
        log_success "1Password CLI installed: ${version}"
    else
        log_warning "1Password CLI not installed (optional)"
    fi
}

# Test: chezmoi init with test repo
test_chezmoi_init() {
    log_info "Testing: chezmoi init from GitHub"
    
    # Use a test repository (fork or test repo)
    # For testing, we can use the actual repo or a minimal test
    if chezmoi init rudironsoni --destination "${HOME}/.local/share/chezmoi-test"; then
        log_success "chezmoi init successful"
    else
        log_error "chezmoi init failed"
    fi
}

# Test: Apply dotfiles (dry-run)
test_chezmoi_apply_dry_run() {
    log_info "Testing: chezmoi apply (dry-run)"
    
    if chezmoi apply --dry-run --destination "${HOME}/.local/share/chezmoi-test"; then
        log_success "chezmoi apply (dry-run) successful"
    else
        log_error "chezmoi apply (dry-run) failed"
    fi
}

# Test: Template variables are available
test_template_variables() {
    log_info "Testing: Template variables"
    
    # Test OS detection
    local os
    os=$(chezmoi data get "chezmoi.os")
    
    if [ -n "$os" ]; then
        log_success "Template variable .chezmoi.os = ${os}"
    else
        log_error "Template variable .chezmoi.os not available"
    fi
    
    # Test hostname
    local hostname
    hostname=$(chezmoi data get "chezmoi.hostname")
    
    if [ -n "$hostname" ]; then
        log_success "Template variable .chezmoi.hostname = ${hostname}"
    else
        log_error "Template variable .chezmoi.hostname not available"
    fi
    
    # Test username
    local username
    username=$(chezmoi data get "chezmoi.username")
    
    if [ -n "$username" ]; then
        log_success "Template variable .chezmoi.username = ${username}"
    else
        log_error "Template variable .chezmoi.username not available"
    fi
}

# Test: Config files exist
test_config_files() {
    log_info "Testing: Config files exist in source state"
    
    local config_dir="${HOME}/.local/share/chezmoi-test"
    
    # Check shell configs
    for file in ".bashrc" ".zshrc" ".profile"; do
        if [ -f "${config_dir}/home/${file}.tmpl" ]; then
            log_success "Config file exists: ${file}.tmpl"
        else
            log_error "Config file missing: ${file}.tmpl"
        fi
    done
    
    # Check .config directory
    if [ -d "${config_dir}/home/.config" ]; then
        log_success ".config directory exists"
    else
        log_error ".config directory missing"
    fi
}

# Test: Bootstrap script syntax
test_bootstrap_script() {
    log_info "Testing: Bootstrap script syntax"
    
    if bash -n "${HOME}/.local/share/chezmoi-test/scripts/bootstrap.sh" 2>/dev/null; then
        log_success "Bootstrap script syntax valid"
    else
        log_warning "Bootstrap script not found or has syntax errors"
    fi
}

# Test: Docker environment detection
test_docker_detection() {
    log_info "Testing: Docker environment detection"
    
    # Check if running in Docker
    if [ -f "/.dockerenv" ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
        log_success "Docker environment detected"
    else
        log_warning "Docker environment not detected"
    fi
}

# Main
main() {
    echo "=========================================="
    echo "  Chezmoi Test Suite"
    echo "=========================================="
    echo ""
    
    # Run tests
    test_chezmoi_installed
    test_1password_installed
    test_docker_detection
    
    echo ""
    
    test_chezmoi_init
    test_chezmoi_apply_dry_run
    
    echo ""
    
    test_template_variables
    test_config_files
    test_bootstrap_script
    
    echo ""
    echo "=========================================="
    echo "  Test Results"
    echo "=========================================="
    echo -e "${GREEN}Passed:${NC} ${PASS}"
    echo -e "${RED}Failed:${NC} ${FAIL}"
    echo ""
    
    if [ "$FAIL" -gt 0 ]; then
        echo -e "${RED}Some tests failed!${NC}"
        exit 1
    else
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    fi
}

main "$@"
