# Installation Guide

Complete step-by-step instructions for setting up these dotfiles on a new machine.

## Prerequisites

### macOS

- macOS 10.15 (Catalina) or later
- Homebrew installed
- Administrator access

### Linux

- Ubuntu 20.04+, Debian 11+, Fedora 35+, Arch Linux, or openSUSE
- `curl` or `wget` installed
- `sudo` access (for package installation)

### Windows

- Windows 10/11 with WSL2, or Windows Server 2019+
- PowerShell 7+ (for PowerShell configs)

## Quick Install

### One-Command Bootstrap

The fastest way to get started is using the bootstrap script:

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/rudironsoni/dotfiles/main/scripts/bootstrap.sh)"
```

### Manual Installation

#### Step 1: Install chezmoi

**macOS:**
```bash
brew install chezmoi 1password-cli
```

**Linux (install script):**
```bash
sh -c "$(curl -fsLS get.chezmoi.io)"
export PATH="$HOME/.local/bin:$PATH"
```

**Linux (Homebrew):**
```bash
brew install chezmoi 1password-cli
```

#### Step 2: Initialize dotfiles

```bash
# Using HTTPS (recommended for first-time setup)
chezmoi init --apply rudironsoni

# Or using SSH (if you have SSH keys set up)
chezmoi init --apply git@github.com:rudironsoni/dotfiles.git
```

#### Step 3: Apply the configuration

```bash
chezmoi apply
```

## Post-Installation Setup

### 1. Configure 1Password (Optional but recommended)

If you use 1Password for secrets:

```bash
# Install 1Password CLI
brew install 1password-cli  # macOS
# or follow: https://developer.1password.com/docs/cli/get-started/

# Sign in
eval $(op signin)

# Re-apply dotfiles to inject secrets
chezmoi apply
```

### 2. Set up shell

**Zsh (macOS default):**
```bash
# Zsh is already configured
chsh -s /bin/zsh  # Set as default shell
```

**Bash:**
```bash
# Bash configuration is applied
chsh -s /bin/bash  # Set as default shell
```

**Fish:**
```bash
# Fish configuration is applied
chsh -s $(which fish)  # Set as default shell
```

### 3. Install tmux plugins

```bash
# TPM and plugins are installed automatically by chezmoi
# Reload tmux configuration
tmux source ~/.config/tmux/tmux.conf

# In tmux, press prefix + I to install plugins
# Default prefix is Ctrl+B
```

### 4. Set up Neovim

```bash
# Open Neovim - plugins will install automatically on first run
nvim

# Run :checkhealth to verify setup
# Run :Mason to install language servers
```

### 5. Configure Git

Git is automatically configured using your chezmoi data. To update:

```bash
# Edit local data
chezmoi data

# Edit the config file
chezmoi edit-config

# Or set values directly
chezmoi init --promptString email="your@email.com"
chezmoi init --promptString name="Your Name"
```

## Platform-Specific Notes

### macOS

- Homebrew packages are installed automatically via chezmoiscripts
- 1Password CLI is installed automatically
- Oh My Posh is installed for prompt customization

### Linux

- Package manager is auto-detected (apt, dnf, pacman, zypper)
- Chezmoi is installed if not present
- Additional tools are installed via the chezmoiscript

### WSL (Windows Subsystem for Linux)

- Windows paths are automatically handled
- Windows SSH agent integration is configured
- Cross-platform clipboard works via OSC 52

### GitHub Codespaces

- Pre-installed tools are detected and skipped
- Container-specific configurations are applied
- Dotfiles apply automatically on container creation

### Docker/Containers

- Minimal configuration is applied
- Hooks and scripts are skipped
- Useful for CI/CD environments

## Customization

### Machine-Specific Configuration

Create `.chezmoidata.yaml` in your source directory:

```yaml
email: "work@example.com"
name: "Work User"
shell: "zsh"
```

### Environment Variables

You can customize behavior with environment variables:

```bash
# Skip certain tools
export DOTFILES_SKIP_1PASSWORD=1
export DOTFILES_SKIP_NEOVIM=1

# Force specific settings
export DOTFILES_THEME="dark"
```

### Adding New Files

```bash
# Add a file to chezmoi
chezmoi add ~/.myconfig

# Add with template
chezmoi add --template ~/.myconfig

# Edit the source
chezmoi edit ~/.myconfig
```

## Troubleshooting

### Permission Denied Errors

```bash
# Fix permissions on chezmoi directory
chmod 700 ~/.local/share/chezmoi
```

### Templates Not Rendering

```bash
# Test a specific template
chezmoi cat ~/.config/myconfig

# Debug template execution
chezmoi execute-template < ~/.local/share/chezmoi/path/to/template.tmpl
```

### Package Installation Fails

```bash
# Skip the chezmoiscript
chezmoi apply --exclude=scripts

# Install packages manually, then apply
chezmoi apply
```

### 1Password Not Working

```bash
# Check if op CLI is available
which op
op --version

# Sign in manually
eval $(op signin)

# Verify vault access
op vault list
```

## Verification

After installation, verify everything is working:

```bash
# Check chezmoi health
chezmoi doctor

# Verify template data
chezmoi data | jq

# Check for managed files
chezmoi managed

# Compare local with source
chezmoi diff
```

## Uninstallation

To remove dotfiles and restore original configurations:

```bash
# Remove chezmoi-managed files (backs up originals)
chezmoi purge

# Or just stop managing (keeps current files)
chezmoi unmanaged
```

## Getting Help

- [Chezmoi Documentation](https://www.chezmoi.io/)
- [Chezmoi Reference](https://www.chezmoi.io/reference/)
- [GitHub Issues](https://github.com/rudironsoni/dotfiles/issues)

## See Also

- [TOOLS.md](./TOOLS.md) - List of configured tools
- [SECURITY.md](./SECURITY.md) - Security and secrets handling
- [README.md](./README.md) - Overview and features
