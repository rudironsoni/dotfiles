# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a dotfiles repository managed by [chezmoi](https://www.chezmoi.io/), with 1Password integration for secrets. It supports macOS, Linux (Ubuntu/Debian/Fedora/Arch/openSUSE), and Windows (WSL/PowerShell).

## Architecture

### Chezmoi Configuration

- **Source state root**: `home/` (configured in `.chezmoiroot`)
- **Configuration template**: `.chezmoi.toml.tmpl` - Sets up 1Password CLI hook, auto-detects git config for user data, defines template data (email, name, is_wsl, is_codespace, etc.)
- **External dependencies**: `.chezmoiexternal.toml` - TPM-Redux (tmux plugin manager), zsh plugins
- **Package definitions**: `.chezmoidata/packages.yaml` - Declarative OS-specific package lists

### File Naming Conventions

Chezmoi uses specific prefixes in the source state (`home/`):

| Prefix | Result | Example |
|--------|--------|---------|
| `dot_` | `.` prefix | `dot_zshrc` → `~/.zshrc` |
| `private_` | 0600 permissions | `private_dot_ssh/config` |
| `executable_` | Executable bit | `executable_script.sh` |
| `literal_` | No transformation | `literal_dot_keep` |
| `symlink_` | Symlink | `symlink_dot_vimrc` |

Templates use the `.tmpl` suffix: `dot_zshrc.tmpl`

### Template Data

Available template variables (defined in `.chezmoi.toml.tmpl`):

- `.email`, `.name` - Git user config (auto-detected from git, with env/CI fallbacks)
- `.is_wsl`, `.is_codespace`, `.is_container` - Environment detection
- `.has_1password`, `.has_docker`, `.has_kubectl` - Tool availability
- `.chezmoi.os`, `.chezmoi.arch`, `.chezmoi.hostname` - Built-in chezmoi data

**Init behavior**: The template uses a fallback hierarchy for email/name:
1. `CHEZMOI_EMAIL` / `CHEZMOI_NAME` env vars (highest priority)
2. Auto-detect from `git config --global`
3. CI defaults when `CI=true` (non-interactive)
4. Interactive `promptString` (lowest priority)

### 1Password Integration

- **Install hook**: `.install-1password.sh` runs before chezmoi reads source state (via `hooks.read-source-state.pre`)
- **Secret references**: Use `{{ output "op" "read" "op://vault/item/field" }}` in templates
- **Service account**: Set `OP_SERVICE_ACCOUNT_TOKEN` for CI/automation

### Scripts

- **`home/.chezmoiscripts/`**: Auto-run scripts during `chezmoi apply`
  - `run_onchange_*` - Runs when file content changes (for package installation)
  - `run_once_*` - Runs only once per machine
  - `executable_*` - Scripts that need executable permissions

## Common Commands

### Development

```bash
# Apply dotfiles to current machine
chezmoi apply

# Edit a file in the source state
chezmoi edit ~/.zshrc

# Edit directly (after initial setup)
chezmoi edit home/dot_zshrc.tmpl

# Check what would change (dry run)
chezmoi apply --dry-run

# View chezmoi data context
chezmoi data | jq

# Test template rendering
chezmoi execute-template < home/dot_zshrc.tmpl

# Validate chezmoi configuration
chezmoi doctor

# List managed files
chezmoi managed
```

### Testing

```bash
# Run full test matrix (all distros)
./tests/run-matrix.sh

# Test specific distros
./tests/run-matrix.sh --distros ubuntu,debian

# Run tests in parallel
./tests/run-matrix.sh --parallel

# Legacy test script
./scripts/test-docker.sh --all

# Validate templates only
bash tests/validate-templates.sh
```

### Linting

```bash
# Shellcheck (from repo root)
shellcheck -e SC2148 -e SC1090 home/.chezmoiscripts/*.sh

# YAML lint
yamllint -d relaxed .
```

## CI/CD

GitHub Actions workflows (`.github/workflows/`):

- **`test-dotfiles.yml`**: Tests on native platforms (Linux, macOS, Windows) + Docker matrix (Ubuntu, Debian, Fedora, Arch)
- **`lint.yml`**: ShellCheck, yamllint, and secret detection

The Docker test matrix uses base images with chezmoi and 1Password CLI pre-installed to test the full initialization flow.

## Package Management

Packages are defined declaratively in `.chezmoidata/packages.yaml`:

```yaml
packages:
  darwin:
    brews: [chezmoi, git, zsh, ...]
    casks: []
  linux:
    common: [git, zsh, ...]
    apt: [ripgrep, fd-find, ...]
    dnf: [ripgrep, fd-find, ...]
    pacman: [ripgrep, fd, ...]
```

The `run_onchange_install-packages-*.sh.tmpl` scripts read this file and install packages using the appropriate package manager. The `onchange` prefix means they only re-run when the script content changes (tracked via hash).

## Adding New Files

```bash
# Add existing file to chezmoi
chezmoi add ~/.myconfig

# Add as template
chezmoi add --template ~/.myconfig

# Create new file directly
chezmoi edit ~/.myconfig
```

## Security Notes

- Never commit hardcoded secrets - use 1Password references
- Use `private_` prefix for sensitive files (SSH keys, tokens)
- The `validate-templates.sh` script scans for potential secrets
- CI runs TruffleHog for secret detection on PRs
