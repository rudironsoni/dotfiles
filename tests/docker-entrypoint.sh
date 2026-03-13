#!/bin/bash
# Docker entrypoint for dotfiles tests
# Configures 1Password authentication if token is available

set -e

# Configure 1Password if service account token is available
if [ -n "$OP_SERVICE_ACCOUNT_TOKEN" ]; then
    echo "Configuring 1Password service account..."
    export OP_ACCOUNT="my.1password.com"
    
    # Verify authentication works
    if op vault list >/dev/null 2>&1; then
        echo "1Password authenticated successfully"
    else
        echo "Warning: 1Password authentication failed"
    fi
fi

# Execute the command passed to the container
exec "$@"
