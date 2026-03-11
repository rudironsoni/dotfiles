#!/usr/bin/env bash
# ==============================================================================
# Multi-Distro Test Matrix Runner
# ==============================================================================
# This script builds and tests dotfiles across multiple Linux distributions
#
# Usage: ./tests/run-matrix.sh [options]
#
# Options:
#   --distros d1,d2    Comma-separated list of distros to test (default: all)
#   --parallel         Run tests in parallel (default: sequential)
#   --no-build         Skip building images (use existing)
#   --no-clean         Don't clean up images after testing
#   --verbose          Show verbose output
#
# Examples:
#   ./tests/run-matrix.sh                    # Test all distros sequentially
#   ./tests/run-matrix.sh --distros debian,ubuntu  # Test specific distros
#   ./tests/run-matrix.sh --parallel         # Test all in parallel
#
# ==============================================================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Available distros
DISTROS=("ubuntu" "debian" "fedora" "arch")
SELECTED_DISTROS=()
PARALLEL=false
NO_BUILD=false
NO_CLEAN=false
VERBOSE=false

# Results tracking
declare -A RESULTS

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_distro() {
    local distro="$1"
    local message="$2"
    echo -e "${CYAN}[${distro}]${NC} ${message}"
}

usage() {
    cat << EOF
Usage: $0 [options]

Options:
  --distros d1,d2    Comma-separated list of distros to test (default: all)
  --parallel         Run tests in parallel
  --no-build         Skip building images (use existing)
  --no-clean         Don't clean up images after testing
  --verbose          Show verbose output
  --help             Show this help message

Available distros: ${DISTROS[*]}

Examples:
  $0                           # Test all distros sequentially
  $0 --distros debian,ubuntu   # Test specific distros
  $0 --parallel                # Test all in parallel
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --distros)
                IFS=',' read -ra SELECTED_DISTROS <<< "$2"
                shift 2
                ;;
            --parallel)
                PARALLEL=true
                shift
                ;;
            --no-build)
                NO_BUILD=true
                shift
                ;;
            --no-clean)
                NO_CLEAN=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --help)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    # Default to all distros if none specified
    if [ ${#SELECTED_DISTROS[@]} -eq 0 ]; then
        SELECTED_DISTROS=("${DISTROS[@]}")
    fi
}

# Get Dockerfile path for distro
get_dockerfile() {
    local distro="$1"
    case "$distro" in
        ubuntu)
            echo "${SCRIPT_DIR}/Dockerfile.linux"
            ;;
        *)
            echo "${SCRIPT_DIR}/Dockerfile.${distro}"
            ;;
    esac
}

build_image() {
    local distro="$1"
    local image_name="dotfiles-test:${distro}"
    local dockerfile
    dockerfile=$(get_dockerfile "$distro")

    if [ ! -f "$dockerfile" ]; then
        log_distro "$distro" "${RED}Dockerfile not found: ${dockerfile}${NC}"
        return 1
    fi

    if [ "$NO_BUILD" = true ]; then
        if docker image inspect "$image_name" &> /dev/null; then
            log_distro "$distro" "Using existing image"
            return 0
        else
            log_distro "$distro" "Image not found, building..."
        fi
    fi

    log_distro "$distro" "Building image..."

    local build_args=()
    if [ "$VERBOSE" = false ]; then
        build_args+=("--quiet")
    fi

    if docker build "${build_args[@]}" -f "$dockerfile" -t "$image_name" "$PROJECT_ROOT"; then
        log_distro "$distro" "${GREEN}Build successful${NC}"
        return 0
    else
        log_distro "$distro" "${RED}Build failed${NC}"
        return 1
    fi
}

run_tests() {
    local distro="$1"
    local image_name="dotfiles-test:${distro}"

    log_distro "$distro" "Running tests..."

    # Create temporary directory for test results
    local temp_dir
    temp_dir=$(mktemp -d)

    local run_args=(
        --rm
        -v "${PROJECT_ROOT}:/home/testuser/dotfiles:ro"
        -e "TEST_MODE=true"
        -e "CI=true"
    )

    # Run main test suite
    if docker run "${run_args[@]}" "$image_name" \
        bash -c "cd /home/testuser/dotfiles && bash tests/test-chezmoi.sh" \
        > "${temp_dir}/test-output.txt" 2>&1; then

        log_distro "$distro" "${GREEN}Main tests passed${NC}"
        RESULTS[$distro]="PASS"
    else
        log_distro "$distro" "${RED}Main tests failed${NC}"
        if [ "$VERBOSE" = true ]; then
            cat "${temp_dir}/test-output.txt"
        fi
        RESULTS[$distro]="FAIL"
    fi

    # Run template validation if main tests passed
    if [ "${RESULTS[$distro]}" = "PASS" ]; then
        log_distro "$distro" "Running template validation..."

        if docker run "${run_args[@]}" "$image_name" \
            bash -c "cd /home/testuser/dotfiles && bash tests/validate-templates.sh /home/testuser/dotfiles" \
            > "${temp_dir}/validate-output.txt" 2>&1; then

            log_distro "$distro" "${GREEN}Template validation passed${NC}"
        else
            log_distro "$distro" "${YELLOW}Template validation had warnings${NC}"
            if [ "$VERBOSE" = true ]; then
                cat "${temp_dir}/validate-output.txt"
            fi
        fi
    fi

    # Cleanup
    rm -rf "$temp_dir"
}

clean_image() {
    local distro="$1"
    local image_name="dotfiles-test:${distro}"

    if [ "$NO_CLEAN" = true ]; then
        return 0
    fi

    log_distro "$distro" "Cleaning up..."
    docker rmi -f "$image_name" > /dev/null 2>&1 || true
}

test_distro() {
    local distro="$1"

    echo ""
    log_info "============================================"
    log_info "Testing: ${distro}"
    log_info "============================================"

    if build_image "$distro"; then
        run_tests "$distro"
    else
        RESULTS[$distro]="BUILD_FAIL"
    fi

    clean_image "$distro"
}

print_summary() {
    echo ""
    echo ""
    echo "=========================================="
    echo "  Test Matrix Results"
    echo "=========================================="

    local pass_count=0
    local fail_count=0

    for distro in "${DISTROS[@]}"; do
        if [[ " ${SELECTED_DISTROS[*]} " =~ " ${distro} " ]]; then
            local result="${RESULTS[$distro]:-SKIP}"
            case "$result" in
                PASS)
                    printf "  ${GREEN}%-10s${NC} %s\n" "$distro" "✓ PASSED"
                    ((pass_count++))
                    ;;
                FAIL)
                    printf "  ${RED}%-10s${NC} %s\n" "$distro" "✗ FAILED"
                    ((fail_count++))
                    ;;
                BUILD_FAIL)
                    printf "  ${RED}%-10s${NC} %s\n" "$distro" "✗ BUILD FAILED"
                    ((fail_count++))
                    ;;
                *)
                    printf "  ${YELLOW}%-10s${NC} %s\n" "$distro" "- SKIPPED"
                    ;;
            esac
        fi
    done

    echo "=========================================="
    echo "  Total: ${pass_count} passed, ${fail_count} failed"
    echo "=========================================="

    if [ $fail_count -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
}

main() {
    parse_args "$@"

    echo "=========================================="
    echo "  Docker Test Matrix Runner"
    echo "=========================================="
    echo "  Distros: ${SELECTED_DISTROS[*]}"
    echo "  Parallel: ${PARALLEL}"
    echo "  Build: $([ "$NO_BUILD" = true ] && echo 'skip' || echo 'yes')"
    echo "  Clean: $([ "$NO_CLEAN" = true ] && echo 'no' || echo 'yes')"
    echo "=========================================="

    # Check Docker is available
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        exit 1
    fi

    # Check Docker is running
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running"
        exit 1
    fi

    # Run tests
    if [ "$PARALLEL" = true ]; then
        log_info "Running tests in parallel..."
        for distro in "${SELECTED_DISTROS[@]}"; do
            test_distro "$distro" &
        done
        wait
    else
        log_info "Running tests sequentially..."
        for distro in "${SELECTED_DISTROS[@]}"; do
            test_distro "$distro"
        done
    fi

    print_summary
}

main "$@"
