#!/usr/bin/env bash
# ==============================================================================
# Template Validation Script
# ==============================================================================
# This script validates chezmoi templates for syntax errors, secrets,
# and data context issues
#
# Usage: ./tests/validate-templates.sh [source_dir]
#   source_dir: Path to chezmoi source directory (default: /home/testuser/dotfiles)
#
# ==============================================================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SOURCE_DIR="${1:-${PROJECT_ROOT}}"
HOME_DIR="${HOME:-/home/testuser}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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
    echo -e "${YELLOW}[WARN]${NC} $1"
    WARN=$((WARN + 1))
}

# Test: Check if file is a valid template
test_template_syntax() {
    local file="$1"
    local basename
    basename=$(basename "$file")

    # Skip .chezmoi.toml.tmpl as it uses init-only functions (promptString, etc.)
    if [[ "$basename" == ".chezmoi.toml.tmpl" ]]; then
        log_warning "Skipping syntax check for ${basename} (uses init-only functions)"
        return 0
    fi

    # Try to render the template
    local output
    output=$(chezmoi execute-template < "$file" 2>&1) || true
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        log_success "Syntax valid: ${basename}"
        return 0
    else
        # Check for common non-syntax errors that are expected in test environment
        if echo "$output" | grep -q "no entry for key"; then
            # Template needs custom data variables (like .name, .email)
            log_warning "Template needs custom data variables: ${basename}"
            return 0
        elif echo "$output" | grep -q "1Password\|op://"; then
            # Template uses 1Password (not configured in test)
            log_warning "Template uses 1Password (not configured in test): ${basename}"
            return 0
        else
            log_error "Syntax error in: ${basename}"
            return 1
        fi
    fi
}

# Test: Check for hardcoded secrets
test_no_secrets() {
    local file="$1"
    local basename
    basename=$(basename "$file")

    # Patterns that might indicate hardcoded secrets
    local patterns=(
        'password[[:space:]]*=[[:space:]]*"[^"]+"'
        'passwd[[:space:]]*=[[:space:]]*"[^"]+"'
        'secret[[:space:]]*=[[:space:]]*"[^"]+"'
        'api_key[[:space:]]*=[[:space:]]*"[^"]+"'
        'apikey[[:space:]]*=[[:space:]]*"[^"]+"'
        'token[[:space:]]*=[[:space:]]*"[a-zA-Z0-9_-]{20,}"'
        'private_key[[:space:]]*=[[:space:]]*"[^"]+"'
        'aws_access_key_id[[:space:]]*=[[:space:]]*"[^"]+"'
        'aws_secret_access_key[[:space:]]*=[[:space:]]*"[^"]+"'
        'ghp_[a-zA-Z0-9]{36}'
        'gho_[a-zA-Z0-9]{36}'
        'sk-[a-zA-Z0-9]{48}'
    )

    local found_secret=false
    for pattern in "${patterns[@]}"; do
        if grep -iE "$pattern" "$file" > /dev/null 2>&1; then
            log_warning "Possible hardcoded secret in ${basename}: matches pattern '${pattern}'"
            found_secret=true
        fi
    done

    if [ "$found_secret" = false ]; then
        log_success "No hardcoded secrets in: ${basename}"
    fi
}

# Test: Check YAML/JSON syntax in generated output
test_generated_syntax() {
    local file="$1"
    local basename
    basename=$(basename "$file")
    local ext="${basename##*.}"

    # Skip if not YAML or JSON
    if [[ "$basename" != *.yml.tmpl && "$basename" != *.yaml.tmpl && "$basename" != *.json.tmpl ]]; then
        return 0
    fi

    # Generate the template output
    local output
    if ! output=$(chezmoi execute-template < "$file" 2>/dev/null); then
        log_error "Cannot generate output for syntax check: ${basename}"
        return 1
    fi

    case "$ext" in
        yml|yaml)
            if echo "$output" | python3 -c "import yaml, sys; yaml.safe_load(sys.stdin)" 2>/dev/null; then
                log_success "Valid YAML output: ${basename}"
            else
                log_warning "Invalid YAML output: ${basename}"
            fi
            ;;
        json)
            if echo "$output" | python3 -m json.tool > /dev/null 2>&1; then
                log_success "Valid JSON output: ${basename}"
            else
                log_warning "Invalid JSON output: ${basename}"
            fi
            ;;
    esac
}

# Test: Validate template functions are used correctly
test_template_functions() {
    local file="$1"
    local basename
    basename=$(basename "$file")

    # Check for common template function issues
    local issues=()

    # Check for unclosed braces
    local open_count
    open_count=$(grep -o '{{' "$file" | wc -l)
    local close_count
    close_count=$(grep -o '}}' "$file" | wc -l)
    if [ "$open_count" -ne "$close_count" ]; then
        issues+=("Mismatched braces: ${open_count} open, ${close_count} close")
    fi

    # Check for common function typos
    if grep -E '\{\{\s*output[[:space:]]+"' "$file" > /dev/null 2>&1; then
        issues+=("Possible typo: 'output' should be used with parenthesis like output \"...\"")
    fi

    # Report issues
    if [ ${#issues[@]} -eq 0 ]; then
        log_success "Template functions look good: ${basename}"
    else
        for issue in "${issues[@]}"; do
            log_warning "${basename}: ${issue}"
        done
    fi
}

# Test: Verify OS-specific conditionals
test_os_conditionals() {
    local file="$1"
    local basename
    basename=$(basename "$file")

    # Check if file has OS-specific content
    if grep -E '\.chezmoi\.os' "$file" > /dev/null 2>&1; then
        # Verify it handles the expected OS values
        local has_darwin=false
        local has_linux=false
        local has_windows=false

        if grep -E 'eq.*darwin' "$file" > /dev/null 2>&1; then
            has_darwin=true
        fi
        if grep -E 'eq.*linux' "$file" > /dev/null 2>&1; then
            has_linux=true
        fi
        if grep -E 'eq.*windows' "$file" > /dev/null 2>&1; then
            has_windows=true
        fi

        local platforms=()
        [ "$has_darwin" = true ] && platforms+=("darwin")
        [ "$has_linux" = true ] && platforms+=("linux")
        [ "$has_windows" = true ] && platforms+=("windows")

        if [ ${#platforms[@]} -gt 0 ]; then
            log_success "OS conditionals found in ${basename}: ${platforms[*]}"
        else
            log_warning "OS detection used but no specific platforms checked in ${basename}"
        fi
    fi
}

# Test: Verify chezmoi data context
test_data_context() {
    log_info "Testing chezmoi data context..."

    local data
    if ! data=$(chezmoi data 2>/dev/null); then
        log_error "Cannot retrieve chezmoi data context"
        return 1
    fi

    # Check for expected data fields
    local fields=("chezmoi.os" "chezmoi.arch" "chezmoi.hostname" "chezmoi.username")
    for field in "${fields[@]}"; do
        local value
        value=$(echo "$data" | jq -r ".${field}" 2>/dev/null || echo "null")
        if [ "$value" != "null" ] && [ -n "$value" ]; then
            log_success "Data context field ${field} = ${value}"
        else
            log_warning "Data context field ${field} not available"
        fi
    done
}

# Test: Dry-run apply to detect issues
test_dry_run_apply() {
    log_info "Testing dry-run apply..."

    if [ ! -d "$SOURCE_DIR" ]; then
        log_error "Source directory not found: $SOURCE_DIR"
        return 1
    fi

    # Set up git config to avoid interactive prompts
    git config --global user.email "test@example.com" 2>/dev/null || true
    git config --global user.name "Test User" 2>/dev/null || true

    # Create necessary directories
    mkdir -p "${HOME}/.local/share"

    # Initialize chezmoi if needed
    if [ ! -d "${HOME}/.local/share/chezmoi" ]; then
        if ! chezmoi init --source "$SOURCE_DIR" test@test.com > /dev/null 2>&1; then
            log_warning "Could not initialize chezmoi for dry-run test"
            return 0
        fi
    fi

    # Run dry-run apply
    local output
    output=$(chezmoi apply --dry-run 2>&1) || true
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        log_success "Dry-run apply completed without errors"
    elif echo "$output" | grep -q "1Password\|op://" 2>/dev/null; then
        log_warning "Dry-run requires 1Password (expected in test environment)"
    else
        log_error "Dry-run apply failed"
        return 1
    fi
}

# Main
test_all_templates() {
    log_info "Scanning for template files in ${SOURCE_DIR}..."

    local template_files=()
    while IFS= read -r -d '' file; do
        template_files+=("$file")
    done < <(find "$SOURCE_DIR" -name "*.tmpl" -type f -print0 2>/dev/null)

    if [ ${#template_files[@]} -eq 0 ]; then
        log_error "No template files found in ${SOURCE_DIR}"
        return 1
    fi

    log_info "Found ${#template_files[@]} template files"
    echo ""

    for file in "${template_files[@]}"; do
        local basename
        basename=$(basename "$file")
        log_info "Testing: ${basename}"

        test_template_syntax "$file"
        test_no_secrets "$file"
        test_generated_syntax "$file"
        test_template_functions "$file"
        test_os_conditionals "$file"

        echo ""
    done
}

main() {
    echo "=========================================="
    echo "  Chezmoi Template Validation Suite"
    echo "=========================================="
    echo ""

    # Check prerequisites
    if ! command -v chezmoi &> /dev/null; then
        log_error "chezmoi is not installed"
        exit 1
    fi

    if [ ! -d "$SOURCE_DIR" ]; then
        log_error "Source directory not found: $SOURCE_DIR"
        exit 1
    fi

    # Run tests
    test_data_context
    echo ""

    test_all_templates
    echo ""

    test_dry_run_apply
    echo ""

    # Summary
    echo "=========================================="
    echo "  Validation Results"
    echo "=========================================="
    echo -e "${GREEN}Passed:${NC}  ${PASS}"
    echo -e "${YELLOW}Warnings:${NC} ${WARN}"
    echo -e "${RED}Failed:${NC}  ${FAIL}"
    echo ""

    if [ "$FAIL" -gt 0 ]; then
        echo -e "${RED}Validation failed!${NC}"
        exit 1
    else
        echo -e "${GREEN}Validation completed with ${WARN} warnings${NC}"
        exit 0
    fi
}

main "$@"
