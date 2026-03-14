#!/bin/bash
# Tmux plugin installation script
# Runs when tmux.conf changes (due to run_onchange_ prefix)
# https://www.chezmoi.io/reference/special-files/chezmoiscripts/

set -euo pipefail

echo "=== Installing tmux plugins ==="

TPM_DIR="$HOME/.config/tmux/plugins/tpm"

# Install TPM-Redux if not present
if [[ ! -d "$TPM_DIR" ]]; then
    echo "Installing TPM-Redux (Tmux Plugin Manager)..."
    git clone https://github.com/RyanMacG/tpm-redux "$TPM_DIR"
else
    echo "TPM-Redux already installed, updating..."
    git -C "$TPM_DIR" pull
fi

# Source TPM and install plugins
if command -v tmux &> /dev/null; then
    echo "Installing tmux plugins..."
    # Install plugins
    "$TPM_DIR/bin/install_plugins" || true
    echo "Tmux plugins installed successfully"
else
    echo "Tmux not found in PATH. Skipping plugin installation."
    echo "Install tmux and run: ~/.config/tmux/plugins/tpm/bin/install_plugins"
fi

echo "=== Tmux plugin installation complete ==="
