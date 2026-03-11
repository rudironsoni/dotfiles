# Dotfiles

My dotfiles managed with [chezmoi](https://www.chezmoi.io/), with 1Password for secrets.

## Quick Start

```bash
# macOS / Linux
sh -c "$(curl -fsSL https://raw.githubusercontent.com/rudironsoni/dotfiles/main/scripts/bootstrap.sh)"
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
- 1Password CLI (for secrets)

## Installation

### One-Command Bootstrap

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/rudironsoni/dotfiles/main/scripts/bootstrap.sh)"
```

### Manual Installation

```bash
# Install chezmoi
sh -c "$(curl -fsLS get.chezmoi.io)"
export PATH="$HOME/.local/bin:$PATH"

# Initialize dotfiles
chezmoi init --apply rudironsoni

# Or using SSH
chezmoi init --apply git@github.com:rudironsoni/dotfiles.git
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

- **Neovim** with Lazy.nvim, LSP, Treesitter, Telescope
- **tmux** with TPM-Redux plugin manager
- **Git** with lazygit terminal UI
- **GitHub CLI** with full configuration

**Neovim Keybindings:**

| Key | Action |
|-----|--------|
| `<Space>` | Leader key |
| `<Space>ff` | Find files |
| `<Space>fg` | Live grep |
| `<Space>fb` | Buffers |
| `<Space>ee` | Toggle file explorer |
| `<Space>gd` | Go to definition |
| `K` | Hover documentation |

**tmux Keybindings (Prefix: `Ctrl+B`):**

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

### AI Assistants

- **Claude Code** with skills, commands, and hooks
- **Codex CLI** with AGENTS.md
- **OpenCode** with custom skills

### Security

- **1Password** integration for secrets
- **SSH** configuration with agent forwarding
- No hardcoded credentials in repository

## 1Password Integration

1Password is the primary method for managing secrets in these dotfiles.

### Setup

```bash
# Install 1Password CLI
brew install 1password-cli  # macOS
# or follow: https://developer.1password.com/docs/cli/get-started/

# Sign in
eval $(op signin)

# Verify
chezmoi doctor | grep 1password
```

### Required 1Password Items

Create these items in your Personal vault:

| Item Name | Field | Purpose |
|-----------|-------|---------|
| `GitHub MCP Token` | `credential` | GitHub Personal Access Token for MCP |
| `Synthetic API Key` | `credential` | API key for synthetic.new Anthropic proxy |

**Setup commands:**

```bash
op item create --category="API Credential" --title="GitHub MCP Token" --vault="Private" credential="ghp_xxxxxxxxxxxxxxxx"
op item create --category="API Credential" --title="Synthetic API Key" --vault="Private" credential="syn_xxxxxxxxxxxxxxxx"
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
├── .chezmoiignore               # OS-specific exclusions
├── home/                        # Source state (dotfiles content)
│   ├── dot_zshrc.tmpl
│   ├── dot_bashrc.tmpl
│   ├── dot_config/
│   │   ├── nvim/init.lua        # Neovim config
│   │   ├── tmux/tmux.conf       # Tmux + TPM-Redux
│   │   ├── btop/btop.conf       # System monitor
│   │   ├── ranger/rc.conf       # File manager
│   │   └── oh-my-posh/          # Shell prompt
│   ├── dot_claude/              # Claude Code config
│   ├── dot_codex/               # Codex CLI config
│   └── .chezmoiscripts/         # Auto-install scripts
├── scripts/
│   ├── bootstrap.sh             # One-command setup
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

### 2. Set up Shell

```bash
# Zsh (macOS default)
chsh -s /bin/zsh

# Bash
chsh -s /bin/bash

# Fish
chsh -s $(which fish)
```

### 3. Install tmux Plugins

```bash
# In tmux, press prefix + I to install plugins
# Default prefix is Ctrl+B
```

### 4. Set up Neovim

```bash
# Open Neovim - plugins install automatically on first run
nvim

# Run :checkhealth to verify setup
# Run :Mason to install language servers
```

### 5. Configure Git

```bash
# Edit local data
chezmoi data

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
| `~/.claude/.credentials.json` | API keys | Re-authenticate on new machine |
| `~/.config/gh/hosts.yml` | GitHub auth tokens | Use `gh auth login` |
| `~/.config/opencode/antigravity-accounts.json` | Account tokens | Re-authenticate |

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
