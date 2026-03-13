# Dotfiles

My dotfiles managed with [chezmoi](https://www.chezmoi.io/), with 1Password for secrets.

## Table of Contents

- [Quick Start](#quick-start)
- [Supported Operating Systems](#supported-operating-systems)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Features](#features)
  - [Shell Environment](#shell-environment)
  - [Development Tools](#development-tools)
  - [System Tools](#system-tools)
  - [Security](#security)
- [1Password Integration](#1password-integration)
- [Docker Testing](#docker-testing)
- [Repository Structure](#repository-structure)
- [Post-Installation Setup](#post-installation-setup)
- [Platform-Specific Notes](#platform-specific-notes)
- [Customization](#customization)
- [Security](#security-1)
- [Troubleshooting](#troubleshooting)
- [Verification](#verification)
- [Uninstallation](#uninstallation)
- [Getting Help](#getting-help)
- [License](#license)

## Quick Start

```bash
# Install chezmoi and apply dotfiles
chezmoi init --apply rudironsoni
```

## Supported Operating Systems

| OS | Status | Notes |
|----|--------|-------|
| macOS | ✅ Fully supported | Intel & Apple Silicon |
| Ubuntu/Debian | ✅ Fully supported | Auto-detected package manager |
| Fedora/RHEL | ✅ Fully supported | Uses dnf |
| Arch Linux | ✅ Fully supported | Uses pacman |
| openSUSE | ✅ Supported | Uses zypper |
| Windows (WSL) | ✅ Supported | WSL2 recommended |
| Windows (PowerShell) | ✅ Supported | Limited config |
| GitHub Codespaces | ✅ Supported | Container-aware |
| Docker | ✅ Supported | Minimal config |

## Prerequisites

- `curl` or `wget` installed
- `sudo` access (for package installation)
- 1Password account (CLI installed automatically)

## Installation

### Quick Install

```bash
# Install chezmoi (if not already installed)
sh -c "$(curl -fsLS get.chezmoi.io)"

# Initialize and apply dotfiles
chezmoi init --apply rudironsoni
```

### Alternative Methods

```bash
# Using SSH
chezmoi init --apply git@github.com:rudironsoni/dotfiles.git

# First install chezmoi manually, then apply
# See: https://www.chezmoi.io/install/
```

## Features

### Shell Environment

- **Zsh** with Oh My Posh prompt, syntax highlighting, auto-suggestions
- **Bash** with modern configuration
- **PowerShell** for Windows

**Keybindings:**

| Key | Action |
|-----|--------|
| `Ctrl+R` | FZF history search |
| `Ctrl+T` | FZF file search |
| `Alt+C` | FZF directory search |
| `↑/↓` | Search history by prefix |

### Development Tools

- **tmux** with TPM-Redux plugin manager
- **Git** with lazygit terminal UI
- **GitHub CLI** with full configuration

**tmux Keybindings (Prefix: `Ctrl+B`):

| Key | Action |
|-----|--------|
| `Prefix %` | Split vertically |
| `Prefix "` | Split horizontally |
| `Prefix c` | New window |
| `Prefix z` | Zoom pane |
| `Prefix [` | Copy mode |
| `Prefix I` | Install plugins |

### System Tools

- **btop** system monitor with One Dark theme
- **ranger** file manager with vim bindings
- **ripgrep** with smart defaults
- **fd** fast file finder
- **fzf** fuzzy finder integration

**btop Keybindings:**

| Key | Action |
|-----|--------|
| `?` | Help |
| `1-4` | Switch views |
| `k/j` | Navigate processes |
| `dd` | Kill process |
| `f` | Filter processes |

**ranger Keybindings:**

| Key | Action |
|-----|--------|
| `j/k` | Navigate |
| `h/l` | Parent/child directory |
| `yy` | Copy |
| `dd` | Delete |
| `pp` | Paste |
| `zh` | Toggle hidden files |

### Security

- **1Password** integration for secrets
- **SSH** configuration with agent forwarding
- No hardcoded credentials in repository

## 1Password Integration

1Password is the primary method for managing secrets in these dotfiles. The CLI is installed automatically during `chezmoi init` via the `hooks.read-source-state.pre` hook.

### Automatic Installation

1Password CLI is installed **before** chezmoi reads your source state, ensuring secrets are available for templates.

```bash
# The hook runs automatically during init
chezmoi init --apply rudironsoni

# Verify installation
chezmoi doctor | grep 1password
```

**Supported platforms:** macOS (Homebrew), Debian/Ubuntu (apt), Fedora/RHEL (dnf), Windows (winget). Arch and openSUSE require manual installation.

### Manual Installation (if needed)

```bash
# macOS
brew install 1password-cli

# Sign in
eval $(op signin)
```

### Required 1Password Items

Create these items in your Personal vault:

| Item Name | Field | Purpose |
|-----------|-------|---------|
| `Service Account Token` | `credential` | 1Password service account for automation |
| `GitHub MCP Token` | `credential` | GitHub Personal Access Token for MCP |
| `Synthetic API Key` | `credential` | API key for synthetic.new Anthropic proxy (in vault-prd) |

**Setup commands:**

```bash
# Service Account Token (for automation - see 1Password service accounts)
# Create at: https://my.1password.com/developer-tools/service-accounts
# Then store the token:
op item create --category="API Credential" --title="Service Account Token" --vault="Private" credential="ops_xxxxxxxxxxxxxxxx"

# GitHub MCP Token
op item create --category="API Credential" --title="GitHub MCP Token" --vault="Private" credential="ghp_xxxxxxxxxxxxxxxx"

# Synthetic API Key (store in vault-prd vault)
op item create --category="API Credential" --title="Synthetic API Key" --vault="vault-prd" credential="syn_xxxxxxxxxxxxxxxx"
```

### Using Secrets in Templates

```go-template
{{- if lookPath "op" }}
export GITHUB_MCP_TOKEN={{ output "op" "read" "op://Personal/GitHub MCP Token/credential" | trim | quote }}
export SYNTHETIC_API_KEY={{ output "op" "read" "op://Personal/Synthetic API Key/credential" | trim | quote }}
{{- end }}
```

## Docker Testing

This repository includes comprehensive Docker testing:

```bash
# Test all distros
./tests/run-matrix.sh

# Test specific distros
./tests/run-matrix.sh --distros ubuntu,debian

# Run in parallel
./tests/run-matrix.sh --parallel

# Individual test scripts
./scripts/test-docker.sh --all
./tests/validate-templates.sh
./tests/test-chezmoi.sh
```

### Supported Test Distros

- Ubuntu 24.04
- Debian stable
- Fedora latest
- Arch Linux

All Docker images include chezmoi and 1Password CLI for complete testing.

## Repository Structure

```
dotfiles/
├── .chezmoi.toml.tmpl           # Chezmoi configuration with prompts
├── .chezmoiexternal.toml        # External dependencies (TPM, plugins)
├── .chezmoidata.yaml            # Machine-specific data
├── .chezmoidata/                # Declarative configuration
│   └── packages.yaml            # Package definitions (OS-specific)
├── .chezmoiignore               # OS-specific exclusions
├── home/                        # Source state (dotfiles content)
│   ├── dot_zshrc.tmpl
│   ├── dot_bashrc.tmpl
│   ├── dot_config/
│   │   ├── tmux/tmux.conf       # Tmux + TPM-Redux
│   │   ├── btop/btop.conf       # System monitor
│   │   ├── ranger/rc.conf       # File manager
│   │   └── oh-my-posh/          # Shell prompt
│   └── .chezmoiscripts/         # Auto-install scripts
│       └── run_onchange_*       # Declarative package installers
├── scripts/
│   └── test-docker.sh           # Docker test runner
└── tests/                       # Docker tests
    ├── Dockerfile.linux         # Ubuntu base
    ├── Dockerfile.debian
    ├── Dockerfile.fedora
    ├── Dockerfile.arch
    ├── run-matrix.sh            # Multi-distro test runner
    ├── test-chezmoi.sh          # Main test suite
    └── validate-templates.sh    # Template validation
```

## Post-Installation Setup

### 1. Configure 1Password (Optional but recommended)

```bash
# Install 1Password CLI
brew install 1password-cli  # macOS

# Sign in
eval $(op signin)

# Re-apply dotfiles to inject secrets
chezmoi apply
```

### 2. Shell Configuration (Already Applied)

Zsh is configured as the default shell during `chezmoi init`. To verify or change:

```bash
# Check current shell
echo $SHELL

# Switch to Zsh (default)
chsh -s $(which zsh)

# Or switch to Bash if preferred
chsh -s $(which bash)
```

### 3. Install tmux Plugins

```bash
# In tmux, press prefix + I to install plugins
# Default prefix is Ctrl+B
```

### 4. Configure Git

```bash
# Edit local data
chezmoi data

# Or set values directly
chezmoi init --promptString email="your@email.com"
chezmoi init --promptString name="Your Name"
```

## Platform-Specific Notes

### Package Management (Declarative)

Packages are defined in `.chezmoidata/packages.yaml` and installed automatically via `run_onchange_` scripts. When you modify the package list, chezmoi will re-run the installation script on next apply.

**Adding packages:**

```bash
# Edit the package list
chezmoi edit .chezmoidata/packages.yaml

# Apply changes - packages will be installed automatically
chezmoi apply
```

### macOS

- Homebrew packages are installed declaratively from `.chezmoidata/packages.yaml`
- 1Password CLI is installed automatically
- Oh My Posh is installed for prompt customization

### Linux

- Package manager is auto-detected (apt, dnf, pacman, zypper)
- Packages installed declaratively from `.chezmoidata/packages.yaml`
- See: [Install packages declaratively](https://www.chezmoi.io/user-guide/advanced/install-packages-declaratively/)

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

## Security

### No Hardcoded Secrets

Before committing, always check:

```bash
# Search for potential secrets
grep -r -i "password\|secret\|token\|key" --include="*.tmpl" .

# Use the built-in chezmoi check
chezmoi execute-template < path/to/template.tmpl
```

### Private Files

For sensitive files, use the `private_` prefix:

```bash
# This file will have 600 permissions automatically
private_dot_ssh/config
```

### Files Excluded from Repository

| File | Reason | Alternative |
|------|--------|-------------|
| `~/.copilot/config.json` | OAuth tokens | Authenticate with `gh auth login` |
| `~/.config/gh/hosts.yml` | GitHub auth tokens | Use `gh auth login` |

### CI/CD Security

The GitHub Actions workflows include:

- **TruffleHog** secret detection on all PRs
- **Template validation** for syntax errors
- **Hardcoded secret checks** in templates

## Troubleshooting

### Permission Denied Errors

```bash
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
- [1Password CLI Documentation](https://developer.1password.com/docs/cli/)
- [GitHub Issues](https://github.com/rudironsoni/dotfiles/issues)

## License

MIT License - See LICENSE file for details.
