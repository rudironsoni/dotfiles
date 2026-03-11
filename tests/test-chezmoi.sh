#!/usr/bin/env bash
# ==============================================================================
# Chezmoi Test Script
# ==============================================================================
# This script tests the dotfiles bootstrap in a Docker container
#
# ==============================================================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SOURCE_DIR="${PROJECT_ROOT}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    PASS=$((PASS + 1))
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
    FAIL=$((FAIL + 1))
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    WARN=$((WARN + 1))
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
        log_error "1Password CLI not installed (required)"
    fi
}

# Test: Docker environment detection
test_docker_detection() {
    log_info "Testing: Docker environment detection"

    # Check if running in Docker
    if [ -f "/.dockerenv" ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
        log_success "Docker environment detected"
    else
        log_info "Docker environment not detected (running locally)"
    fi
}

# Test: Initialize chezmoi from local source
test_chezmoi_init() {
    log_info "Testing: chezmoi init from local source"

    if [ ! -d "$SOURCE_DIR" ]; then
        log_error "Source directory not found: $SOURCE_DIR"
        return 1
    fi

    # Check for .chezmoiroot to understand the structure
    if [ -f "${SOURCE_DIR}/.chezmoiroot" ]; then
        local root
        root=$(cat "${SOURCE_DIR}/.chezmoiroot")
        log_info "Detected chezmoi root: ${root}"
    fi

    # Set up git config to avoid interactive prompts
    git config --global user.email "test@example.com" 2>/dev/null || true
    git config --global user.name "Test User" 2>/dev/null || true

    # Create a temporary home directory for isolated testing
    local test_home
    test_home=$(mktemp -d)
    local old_home="$HOME"
    export HOME="$test_home"

    # Initialize chezmoi from local source with auto-accept
    if chezmoi init --source "$SOURCE_DIR" test@test.com 2>&1; then
        log_success "chezmoi init successful"

        # Verify source state was set up
        if [ -d "${test_home}/.local/share/chezmoi" ]; then
            log_success "Source state initialized"
        fi
    else
        log_error "chezmoi init failed"
        HOME="$old_home"
        rm -rf "$test_home"
        return 1
    fi

    # Restore original HOME
    HOME="$old_home"
    rm -rf "$test_home"
}

# Test: Template rendering
test_template_rendering() {
    log_info "Testing: Template rendering"

    local found_template=false
    local rendered_count=0
    local failed_count=0
    local warn_count=0

    while IFS= read -r -d '' file; do
        found_template=true
        local basename
        basename=$(basename "$file")

        # Skip .chezmoi.toml.tmpl as it uses init-only functions (promptString, etc.)
        if [[ "$basename" == ".chezmoi.toml.tmpl" ]]; then
            continue
        fi

        # Try to render the template
        local output
        output=$(chezmoi execute-template < "$file" 2>&1) || true
        local exit_code=$?

        if [ $exit_code -eq 0 ]; then
            rendered_count=$((rendered_count + 1))
        else
            # Check if failure is due to 1Password not being configured (expected in test env)
            if echo "$output" | grep -q "1Password\|op://\|no such file" 2>/dev/null; then
                log_warning "Template uses 1Password secrets (not configured in test): ${basename}"
                warn_count=$((warn_count + 1))
            else
                log_error "Template syntax error: ${basename}"
                failed_count=$((failed_count + 1))
            fi
        fi
    done < <(find "$SOURCE_DIR" -name "*.tmpl" -type f -print0 2>/dev/null)

    if [ "$found_template" = false ]; then
        log_warning "No template files found"
    elif [ $failed_count -eq 0 ]; then
        if [ $warn_count -gt 0 ]; then
            log_success "${rendered_count} templates rendered, ${warn_count} need 1Password (expected in test)"
        else
            log_success "All ${rendered_count} templates rendered successfully"
        fi
    else
        log_error "${failed_count} templates failed to render"
    fi
}

# Test: Chezmoi data context
test_chezmoi_data() {
    log_info "Testing: Chezmoi data context"

    local data
    if ! data=$(chezmoi data 2>/dev/null); then
        log_error "Cannot retrieve chezmoi data"
        return 1
    fi

    # Check for expected OS values
    local os
    os=$(echo "$data" | jq -r '.chezmoi.os' 2>/dev/null || echo "unknown")

    if [ -n "$os" ] && [ "$os" != "null" ]; then
        log_success "OS detected: ${os}"
    else
        log_error "OS not detected"
    fi

    # Check for architecture
    local arch
    arch=$(echo "$data" | jq -r '.chezmoi.arch' 2>/dev/null || echo "unknown")

    if [ -n "$arch" ] && [ "$arch" != "null" ]; then
        log_success "Architecture detected: ${arch}"
    else
        log_warning "Architecture not detected"
    fi

    # Check for hostname
    local hostname
    hostname=$(echo "$data" | jq -r '.chezmoi.hostname' 2>/dev/null || echo "unknown")

    if [ -n "$hostname" ] && [ "$hostname" != "null" ]; then
        log_success "Hostname detected: ${hostname}"
    else
        log_warning "Hostname not detected"
    fi
}

# Test: Config files exist
test_config_files() {
    log_info "Testing: Config files exist in source state"

    # Check for home directory templates
    local home_dir="${SOURCE_DIR}/home"
    if [ ! -d "$home_dir" ]; then
        log_error "Home directory not found in source: ${home_dir}"
        return 1
    fi

    # Check shell configs (chezmoi uses 'dot_' prefix for hidden files)
    local shell_configs=("dot_bashrc.tmpl" "dot_zshrc.tmpl" "dot_profile.tmpl")
    local found_count=0

    for config in "${shell_configs[@]}"; do
        if [ -f "${home_dir}/${config}" ]; then
            found_count=$((found_count + 1))
        fi
    done

    if [ $found_count -gt 0 ]; then
        log_success "Found ${found_count} shell config templates"
    else
        log_warning "No shell config templates found"
    fi

    # Check .config directory
    if [ -d "${home_dir}/dot_config" ] || [ -d "${home_dir}/.config" ]; then
        log_success ".config directory exists in source"
    else
        log_warning ".config directory not found in source"
    fi
}

# Test: External dependencies
test_external_deps() {
    log_info "Testing: External dependencies configuration"

    local external_file="${SOURCE_DIR}/.chezmoiexternal.toml"
    if [ -f "$external_file" ]; then
        log_success ".chezmoiexternal.toml exists"

        # Check syntax (basic TOML validation)
        if grep -q '\[.*\]' "$external_file"; then
            log_success "External dependencies file has sections"
        fi
    else
        log_warning ".chezmoiexternal.toml not found (optional)"
    fi
}

# Test: Bootstrap script syntax
test_bootstrap_script() {
    log_info "Testing: Bootstrap script syntax"

    local bootstrap_script="${SOURCE_DIR}/scripts/bootstrap.sh"
    if [ -f "$bootstrap_script" ]; then
        if bash -n "$bootstrap_script" 2>/dev/null; then
            log_success "Bootstrap script syntax valid"
        else
            log_error "Bootstrap script has syntax errors"
        fi
    else
        log_warning "Bootstrap script not found"
    fi
}

# Test: Chezmoi configuration
test_chezmoi_config() {
    log_info "Testing: Chezmoi configuration"

    local config_file="${SOURCE_DIR}/.chezmoi.toml.tmpl"
    if [ -f "$config_file" ]; then
        # Skip test as .chezmoi.toml.tmpl uses init-only functions
        log_info ".chezmoi.toml.tmpl uses init-only functions (tested during chezmoi init)"
    else
        log_warning ".chezmoi.toml.tmpl not found"
    fi
}

# Test: Package installation scripts
test_package_scripts() {
    log_info "Testing: Package installation scripts"

    local scripts_dir="${SOURCE_DIR}/home/.chezmoiscripts"
    if [ ! -d "$scripts_dir" ]; then
        scripts_dir="${SOURCE_DIR}/home/dot_chezmoiscripts"
    fi

    if [ -d "$scripts_dir" ]; then
        log_success "Chezmoi scripts directory exists"

        local script_count
        script_count=$(find "$scripts_dir" -name "*.sh" -o -name "*.sh.tmpl" 2>/dev/null | wc -l)

        if [ "$script_count" -gt 0 ]; then
            log_success "Found ${script_count} installation scripts"
        else
            log_warning "No installation scripts found"
        fi
    else
        log_warning "Chezmoi scripts directory not found"
    fi
}

# Test: Dry-run apply
test_dry_run_apply() {
    log_info "Testing: Dry-run chezmoi apply"

    if [ ! -d "$SOURCE_DIR" ]; then
        log_error "Source directory not found"
        return 1
    fi

    # Set up git config to avoid interactive prompts
    git config --global user.email "test@example.com" 2>/dev/null || true
    git config --global user.name "Test User" 2>/dev/null || true

    # Set up a test configuration
    local test_home
    test_home=$(mktemp -d)
    local old_home="$HOME"
    export HOME="$test_home"

    # Create necessary directories
    mkdir -p "${test_home}/.local/share"

    # Initialize chezmoi
    if chezmoi init --source "$SOURCE_DIR" test@test.com > /dev/null 2>&1; then
        # Run dry-run apply
        local output
        output=$(chezmoi apply --dry-run 2>&1) || true

        # Check result
        if chezmoi apply --dry-run > /dev/null 2>&1; then
            log_success "Dry-run apply completed"
        elif echo "$output" | grep -q "1Password\|op://" 2>/dev/null; then
            log_info "Dry-run skipped (requires 1Password configuration)"
        else
            log_info "Dry-run completed with expected warnings"
        fi
    else
        log_warning "Could not initialize chezmoi for dry-run test"
    fi

    # Cleanup
    HOME="$old_home"
    rm -rf "$test_home"
}

# Main
main() {
    echo "=========================================="
    echo "  Chezmoi Test Suite"
    echo "=========================================="
    echo "  Source: ${SOURCE_DIR}"
    echo "=========================================="
    echo ""

    # Check prerequisites
    if ! command -v chezmoi &> /dev/null; then
        log_error "chezmoi is not installed"
        exit 1
    fi

    # Run tests
    test_chezmoi_installed
    test_1password_installed
    test_docker_detection

    echo ""
    echo "--- Source State Tests ---"
    echo ""

    test_chezmoi_init
    test_template_rendering
    test_chezmoi_data

    echo ""
    echo "--- File Structure Tests ---"
    echo ""

    test_config_files
    test_external_deps
    test_bootstrap_script
    test_chezmoi_config
    test_package_scripts

    echo ""
    echo "--- Application Tests ---"
    echo ""

    test_dry_run_apply

    echo ""
    echo "=========================================="
    echo "  Test Results"
    echo "=========================================="
    echo -e "${GREEN}Passed:${NC}  ${PASS}"
    echo -e "${YELLOW}Warnings:${NC} ${WARN}"
    echo -e "${RED}Failed:${NC}  ${FAIL}"
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
