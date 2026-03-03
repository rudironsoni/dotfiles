#!/usr/bin/env bash
# ==============================================================================
# Test Docker Script
# ==============================================================================
# This script builds a Linux Docker container and tests the dotfiles bootstrap
#
# Usage:
#   ./scripts/test-docker.sh [--build] [--test] [--clean]
#
# Options:
#   --build    Build the Docker image
#   --test     Run the tests
#   --clean    Clean up Docker images
#   --all      Build, test, and clean (default)
#
# ==============================================================================

set -euo pipefail

# Configuration
IMAGE_NAME="dotfiles-test"
CONTAINER_NAME="dotfiles-test-container"

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

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Build Docker image
build_image() {
    log_info "Building Docker image: ${IMAGE_NAME}"
    
    docker build -f tests/Dockerfile.linux -t "${IMAGE_NAME}:latest" .
    
    log_success "Docker image built: ${IMAGE_NAME}:latest"
}

# Run tests
run_tests() {
    log_info "Running tests in Docker container..."
    
    # Check if image exists
    if ! docker image inspect "${IMAGE_NAME}:latest" &> /dev/null; then
        log_warning "Image not found, building first..."
        build_image
    fi
    
    # Run test script
    docker run --rm \
        --name "${CONTAINER_NAME}" \
        -e "TEST_MODE=true" \
        "${IMAGE_NAME}:latest" \
        bash tests/test-chezmoi.sh
    
    log_success "Tests completed"
}

# Clean up
clean() {
    log_info "Cleaning up Docker resources..."
    
    # Remove container (if exists)
    docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true
    
    # Remove image
    docker rmi -f "${IMAGE_NAME}:latest" 2>/dev/null || true
    
    log_success "Cleanup complete"
}

# Main
main() {
    local do_build=false
    local do_test=false
    local do_clean=false
    
    # Parse arguments
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
            --clean)
                do_clean=true
                shift
                ;;
            --all)
                do_build=true
                do_test=true
                do_clean=true
                shift
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Default: all
    if [ "$do_build" = false ] && [ "$do_test" = false ] && [ "$do_clean" = false ]; then
        do_build=true
        do_test=true
        do_clean=true
    fi
    
    echo "=========================================="
    echo "  Docker Test Runner"
    echo "=========================================="
    echo ""
    
    if [ "$do_build" = true ]; then
        build_image
        echo ""
    fi
    
    if [ "$do_test" = true ]; then
        run_tests
        echo ""
    fi
    
    if [ "$do_clean" = true ]; then
        clean
        echo ""
    fi
    
    log_success "Docker test complete!"
}

main "$@"
