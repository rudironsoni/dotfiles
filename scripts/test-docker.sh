#!/usr/bin/env bash
# ==============================================================================
# Test Docker Script
# ==============================================================================
# This script builds a Linux Docker container and tests the dotfiles bootstrap
#
# Usage:
#   ./scripts/test-docker.sh [options]
#
# Options:
#   --build            Build the Docker image
#   --test             Run the tests
#   --validate         Run template validation
#   --clean            Clean up Docker images
#   --all              Build, test, validate, and clean (default)
#   --distro <name>    Use specific distro (ubuntu, debian, fedora, arch)
#   --matrix           Run tests across all distros
#   --matrix-parallel  Run matrix tests in parallel
#
# Examples:
#   ./scripts/test-docker.sh --all
#   ./scripts/test-docker.sh --distro debian --test
#   ./scripts/test-docker.sh --matrix
#
# ==============================================================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

IMAGE_NAME="dotfiles-test"
CONTAINER_NAME="dotfiles-test-container"
DEFAULT_DISTRO="ubuntu"
SELECTED_DISTRO="$DEFAULT_DISTRO"

# Flags
do_build=false
do_test=false
do_validate=false
do_clean=false
do_matrix=false
parallel_matrix=false

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
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

usage() {
    cat << EOF
Usage: $0 [options]

Options:
  --build            Build the Docker image
  --test             Run the tests
  --validate         Run template validation
  --clean            Clean up Docker images
  --all              Build, test, validate, and clean (default)
  --distro <name>    Use specific distro (ubuntu, debian, fedora, arch)
  --matrix           Run tests across all distros
  --matrix-parallel  Run matrix tests in parallel
  --help             Show this help message

Available distros: ubuntu, debian, fedora, arch

Examples:
  $0 --all                    # Build, test, validate, and clean
  $0 --distro debian --test   # Test specific distro
  $0 --matrix                 # Test all distros sequentially
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --build)
                do_build=true
                shift
                ;;
            --test)
                do_test=true
                shift
                ;;
            --validate)
                do_validate=true
                shift
                ;;
            --clean)
                do_clean=true
                shift
                ;;
            --all)
                do_build=true
                do_test=true
                do_validate=true
                do_clean=true
                shift
                ;;
            --distro)
                SELECTED_DISTRO="$2"
                shift 2
                ;;
            --matrix)
                do_matrix=true
                shift
                ;;
            --matrix-parallel)
                do_matrix=true
                parallel_matrix=true
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

    # Default: all
    if [ "$do_build" = false ] && [ "$do_test" = false ] && [ "$do_validate" = false ] && [ "$do_clean" = false ] && [ "$do_matrix" = false ]; then
        do_build=true
        do_test=true
        do_validate=true
        do_clean=true
    fi
}

get_dockerfile() {
    local distro="$1"

    case "$distro" in
        ubuntu)
            echo "${PROJECT_ROOT}/tests/Dockerfile.linux"
            ;;
        debian|fedora|arch)
            echo "${PROJECT_ROOT}/tests/Dockerfile.${distro}"
            ;;
        *)
            log_error "Unknown distro: $distro"
            exit 1
            ;;
    esac
}

get_image_name() {
    local distro="$1"
    echo "${IMAGE_NAME}:${distro}"
}

# Build Docker image
build_image() {
    local distro="${1:-$SELECTED_DISTRO}"
    local dockerfile
    dockerfile=$(get_dockerfile "$distro")
    local image_name
    image_name=$(get_image_name "$distro")

    if [ ! -f "$dockerfile" ]; then
        log_error "Dockerfile not found: $dockerfile"
        return 1
    fi

    log_info "Building Docker image: ${image_name}"

    if docker build -f "$dockerfile" -t "$image_name" "$PROJECT_ROOT"; then
        log_success "Docker image built: ${image_name}"
    else
        log_error "Docker build failed: ${image_name}"
        return 1
    fi
}

# Run tests
run_tests() {
    local distro="${1:-$SELECTED_DISTRO}"
    local image_name
    image_name=$(get_image_name "$distro")

    log_info "Running tests in ${distro} container..."

    # Check if image exists
    if ! docker image inspect "$image_name" &> /dev/null; then
        log_warning "Image not found, building first..."
        if ! build_image "$distro"; then
            return 1
        fi
    fi

    # Run test script
    if docker run --rm \
        --name "${CONTAINER_NAME}" \
        -e "TEST_MODE=true" \
        -v "${PROJECT_ROOT}:/home/testuser/dotfiles:ro" \
        "$image_name" \
        bash -c "cd /home/testuser/dotfiles && bash tests/test-chezmoi.sh"; then

        log_success "Tests completed for ${distro}"
        return 0
    else
        log_error "Tests failed for ${distro}"
        return 1
    fi
}

# Run template validation
run_validation() {
    local distro="${1:-$SELECTED_DISTRO}"
    local image_name
    image_name=$(get_image_name "$distro")

    log_info "Running template validation in ${distro} container..."

    # Check if image exists
    if ! docker image inspect "$image_name" &> /dev/null; then
        log_warning "Image not found, building first..."
        if ! build_image "$distro"; then
            return 1
        fi
    fi

    # Run validation script
    if docker run --rm \
        --name "${CONTAINER_NAME}-validate" \
        -e "TEST_MODE=true" \
        -v "${PROJECT_ROOT}:/home/testuser/dotfiles:ro" \
        "$image_name" \
        bash -c "cd /home/testuser/dotfiles && bash tests/validate-templates.sh /home/testuser/dotfiles"; then

        log_success "Template validation completed for ${distro}"
        return 0
    else
        log_warning "Template validation had warnings for ${distro}"
        return 0  # Don't fail on validation warnings
    fi
}

# Run matrix tests
run_matrix() {
    log_info "Running matrix tests..."

    local matrix_args=()
    if [ "$parallel_matrix" = true ]; then
        matrix_args+=("--parallel")
    fi

    bash "${PROJECT_ROOT}/tests/run-matrix.sh" "${matrix_args[@]}"
}

# Clean up
clean() {
    local distro="${1:-$SELECTED_DISTRO}"
    local image_name
    image_name=$(get_image_name "$distro")

    log_info "Cleaning up Docker resources..."

    # Remove container (if exists)
    docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true
    docker rm -f "${CONTAINER_NAME}-validate" 2>/dev/null || true

    # Remove image
    docker rmi -f "$image_name" 2>/dev/null || true

    log_success "Cleanup complete"
}

# Clean all images
clean_all() {
    log_info "Cleaning up all Docker resources..."

    local distros=("ubuntu" "debian" "fedora" "arch")
    for distro in "${distros[@]}"; do
        local image_name
        image_name=$(get_image_name "$distro")
        docker rmi -f "$image_name" 2>/dev/null || true
    done

    log_success "All cleanup complete"
}

# Main
main() {
    parse_args "$@"

    echo "=========================================="
    echo "  Docker Test Runner"
    echo "=========================================="
    echo "  Distro: ${SELECTED_DISTRO}"
    echo "  Build:  ${do_build}"
    echo "  Test:   ${do_test}"
    echo "  Validate: ${do_validate}"
    echo "  Clean:  ${do_clean}"
    echo "  Matrix: ${do_matrix}"
    echo "=========================================="
    echo ""

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

    # Run matrix if requested
    if [ "$do_matrix" = true ]; then
        run_matrix
        exit $?
    fi

    local exit_code=0

    if [ "$do_build" = true ]; then
        if ! build_image; then
            exit_code=1
        fi
        echo ""
    fi

    if [ "$do_test" = true ] && [ $exit_code -eq 0 ]; then
        if ! run_tests; then
            exit_code=1
        fi
        echo ""
    fi

    if [ "$do_validate" = true ] && [ $exit_code -eq 0 ]; then
        if ! run_validation; then
            log_warning "Validation completed with warnings"
        fi
        echo ""
    fi

    if [ "$do_clean" = true ]; then
        clean
        echo ""
    fi

    if [ $exit_code -eq 0 ]; then
        log_success "Docker test complete!"
    else
        log_error "Docker test failed!"
    fi

    exit $exit_code
}

main "$@"
