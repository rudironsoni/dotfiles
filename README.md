# Dotfiles

My dotfiles managed with [chezmoi](https://www.chezmoi.io/), with 1Password for secrets.

## Supported Operating Systems

- Linux (Ubuntu, Debian, Fedora, Arch)
- macOS
- Windows (WSL, PowerShell)

## Quick Start

### One-Command Bootstrap

#### macOS / Linux

```bash
brew install chezmoi 1password-cli
chezmoi init rudironsoni --apply
```

#### Linux (alternative)

```bash
# Using install script
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin
~/.local/bin/chezmoi init rudironsoni --apply

# Using brew
brew install chezmoi 1password-cli
chezmoi init rudironsoni --apply
```

#### Windows (PowerShell)

```powershell
# Install 1Password CLI
winget install --id AgileBits.1Password -e

# Install chezmoi
winget install --id twpayne.chezmoi -e

# Initialize dotfiles
chezmoi init rudironsoni --apply
```

### Manual Setup

1. Clone this repository:
   ```bash
   git clone https://github.com/rudironsoni/dotfiles.git ~/.dotfiles
   ```

2. Initialize chezmoi:
   ```bash
   chezmoi init
   chezmoi apply
   ```

## Features

- **Shell Configuration**: bash, zsh, PowerShell
- **Git Configuration**: Personalized gitconfig with machine-specific settings
- **Editor Settings**: VS Code, opencode
- **Tool Configuration**: gh CLI, lazygit, topgrade
- **Secrets**: 1Password integration for sensitive data

## Testing

Test the bootstrap on Linux using Docker:

```bash
./scripts/test-docker.sh
```

## Customization

### Machine-Specific Configuration

Use `.chezmoidata.yaml` to override defaults per machine:

```yaml
email: "your-email@example.com"
shell: "zsh"
```

### OS-Specific Templates

Templates use conditional logic:

```bash
{{- if eq .chezmoi.os "darwin" }}
# macOS-specific config
{{- else if eq .chezmoi.os "linux" }}
# Linux-specific config
{{- else if eq .chezmoi.os "windows" }}
# Windows-specific config
{{- end }}
```

## Repository Structure

```
dotfiles/
├── .chezmoi.toml          # chezmoi configuration
├── .chezmoidata.yaml      # Machine-specific data
├── .gitignore
├── README.md
├── scripts/
│   ├── bootstrap.sh       # Main bootstrap script
│   └── test-docker.sh     # Docker test runner
├── tests/
│   ├── Dockerfile.linux   # Linux test container
│   └── test-chezmoi.sh    # Validation script
└── home/                  # Source state (chezmoi source directory)
    ├── .bashrc.tmpl
    ├── .zshrc.tmpl
    ├── .profile.tmpl
    └── .config/
        ├── git/config.tmpl
        ├── gh/config.yml.tmpl
        ├── lazygit/config.yml.tmpl
        ├── topgrade.toml
        ├── Code/User/settings.json.tmpl
        ├── Code/User/keybindings.json.tmpl
        ├── opencode/settings.yml.tmpl
        └── powershell/Microsoft.PowerShell_profile.ps1.tmpl
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
