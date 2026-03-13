#!/bin/sh
# Install 1Password CLI before chezmoi reads source state
# https://www.chezmoi.io/user-guide/advanced/install-your-password-manager-on-init/

# Exit immediately if 1Password CLI is already installed
type op >/dev/null 2>&1 && exit 0

echo "=== Installing 1Password CLI ==="

case "$(uname -s)" in
    Darwin)
        # macOS - use Homebrew
        if command -v brew >/dev/null 2>&1; then
            echo "Installing 1Password CLI via Homebrew..."
            brew install 1password-cli
        else
            echo "Homebrew not found. Please install Homebrew first:"
            echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            exit 1
        fi
        ;;
    Linux)
        # Detect Linux distribution
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            case "$ID" in
                ubuntu|debian)
                    echo "Installing 1Password CLI for Debian/Ubuntu..."
                    curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
                        sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
                    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | \
                        sudo tee /etc/apt/sources.list.d/1password.list
                    sudo apt-get update
                    sudo apt-get install -y 1password-cli
                    ;;
                fedora|rhel|centos|rocky|almalinux)
                    echo "Installing 1Password CLI for Fedora/RHEL..."
                    sudo rpm --import https://downloads.1password.com/linux/keys/1password.asc
                    sudo sh -c 'echo "[1Password]
name=1Password
baseurl=https://downloads.1password.com/linux/rpm/
enabled=1
repo_gpgcheck=1
gpgcheck=1
gpgkey=https://downloads.1password.com/linux/keys/1password.asc" > /etc/yum.repos.d/1password.repo'
                    sudo dnf install -y 1password-cli
                    ;;
                arch|manjaro)
                    echo "Installing 1Password CLI for Arch..."
                    echo "Please install 1Password CLI from AUR manually:"
                    echo "  yay -S 1password-cli"
                    exit 1
                    ;;
                opensuse*)
                    echo "Installing 1Password CLI for openSUSE..."
                    echo "Please install 1Password CLI manually from:"
                    echo "  https://developer.1password.com/docs/cli/get-started/"
                    exit 1
                    ;;
                *)
                    echo "Unknown Linux distribution: $ID"
                    echo "Please install 1Password CLI manually from:"
                    echo "  https://developer.1password.com/docs/cli/get-started/"
                    exit 1
                    ;;
            esac
        else
            echo "Cannot detect Linux distribution"
            echo "Please install 1Password CLI manually from:"
            echo "  https://developer.1password.com/docs/cli/get-started/"
            exit 1
        fi
        ;;
    CYGWIN*|MINGW*|MSYS*)
        # Windows
        if command -v winget >/dev/null 2>&1; then
            echo "Installing 1Password CLI via winget..."
            winget install --id AgileBits.1Password.CLI -e --accept-source-agreements --accept-package-agreements
        else
            echo "winget not found. Please install 1Password CLI manually from:"
            echo "  https://developer.1password.com/docs/cli/get-started/"
            exit 1
        fi
        ;;
    *)
        echo "Unsupported OS: $(uname -s)"
        echo "Please install 1Password CLI manually from:"
        echo "  https://developer.1password.com/docs/cli/get-started/"
        exit 1
        ;;
esac

echo "=== 1Password CLI installed successfully ==="
