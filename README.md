# Dotfiles

My dotfiles managed with [chezmoi](https://www.chezmoi.io/), with 1Password for secrets.

## Quick Start

```bash
# macOS / Linux
sh -c "$(curl -fsSL https://raw.githubusercontent.com/rudironsoni/dotfiles/main/scripts/bootstrap.sh)"
```

See [INSTALL.md](INSTALL.md) for detailed instructions.

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

## Features

### Shell Environment
- **Zsh** with Oh My Posh prompt, syntax highlighting, auto-suggestions
- **Bash** with modern configuration
- **Fish** with full setup
- **PowerShell** for Windows

### Development Tools
- **Neovim** with Lazy.nvim, LSP, Treesitter, Telescope
- **tmux** with TPM-Redux plugin manager
- **Git** with lazygit terminal UI
- **GitHub CLI** with full configuration

### System Tools
- **btop** system monitor with One Dark theme
- **ranger** file manager with vim bindings
- **ripgrep** with smart defaults
- **fd** fast file finder
- **fzf** fuzzy finder integration

### AI Assistants
- **Claude Code** with skills, commands, and hooks
- **Codex CLI** with AGENTS.md
- **OpenCode** with custom skills

### Security
- **1Password** integration for secrets
- **SSH** configuration with agent forwarding
- No hardcoded credentials in repository

## Documentation

- **[INSTALL.md](INSTALL.md)** - Detailed installation guide
- **[TOOLS.md](TOOLS.md)** - Complete tool reference with keybindings
- **[SECURITY.md](SECURITY.md)** - Secrets management and security practices

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
│   │   ├── tmux/tmux.conf.tmpl  # Tmux + TPM-Redux
│   │   ├── btop/btop.conf.tmpl  # System monitor
│   │   ├── ranger/rc.conf.tmpl  # File manager
│   │   ├── oh-my-posh/          # Shell prompt
│   │   └── ...
│   ├── dot_claude/              # Claude Code config
│   ├── dot_codex/               # Codex CLI config
│   ├── dot_ripgreprc.tmpl       # Search tool config
│   └── .chezmoiscripts/         # Auto-install scripts
├── .github/workflows/           # CI/CD
├── scripts/
│   └── bootstrap.sh             # One-command setup
└── tests/                       # Docker tests
```

## 1Password Integration

1. Install 1Password CLI:
   ```bash
   # macOS/Linux
   brew install 1password-cli
   
   # Windows
   winget install --id AgileBits.1Password -e
   ```

2. Sign in:
   ```bash
   eval $(op signin)
   ```

3. Use in templates:
   ```bash
   {{- $secret := output "op" "item" "secret-name" "--field" "password" }}
   ```

## License

MIT License - See LICENSE file for details.
