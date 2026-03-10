# Configured Tools Reference

Complete list of tools configured in these dotfiles with quick reference for keybindings and usage.

## Table of Contents

- [Shell Tools](#shell-tools)
- [Development Tools](#development-tools)
- [Editor](#editor)
- [Terminal Multiplexer](#terminal-multiplexer)
- [System Monitoring](#system-monitoring)
- [File Management](#file-management)
- [Version Control](#version-control)
- [AI Assistants](#ai-assistants)

---

## Shell Tools

### Zsh / Bash

**Configuration:** `~/.zshrc`, `~/.bashrc`

**Key Features:**
- Oh My Posh prompt with git status
- Syntax highlighting (zsh)
- Auto-suggestions (zsh)
- FZF integration
- History search with arrows

**Keybindings:**
| Key | Action |
|-----|--------|
| `Ctrl+R` | FZF history search |
| `Ctrl+T` | FZF file search |
| `Alt+C` | FZF directory search |
| `↑/↓` | Search history by prefix |

### Fish

**Configuration:** `~/.config/fish/config.fish`

**Key Features:**
- Smart autosuggestions
- Syntax highlighting
- Web-based configuration
- Universal variables

---

## Development Tools

### Neovim

**Configuration:** `~/.config/nvim/init.lua`

**Key Features:**
- Lazy.nvim plugin manager
- LSP support (Mason)
- Treesitter syntax highlighting
- Telescope fuzzy finder
- One Dark theme
- Autocompletion (nvim-cmp)
- Git integration (gitsigns)
- File explorer (nvim-tree)

**Keybindings:**
| Key | Action |
|-----|--------|
| `<Space>` | Leader key |
| `<Space>ff` | Find files |
| `<Space>fg` | Live grep |
| `<Space>fb` | Buffers |
| `<Space>ee` | Toggle file explorer |
| `<Space>gd` | Go to definition |
| `<Space>gr` | Find references |
| `<Space>K` | Hover documentation |
| `gd` | Go to definition |
| `gr` | Find references |
| `K` | Hover documentation |
| `[d` | Previous diagnostic |
| `]d` | Next diagnostic |

**Commands:**
```vim
:Mason          " Install language servers
:Lazy           " Plugin manager
:TSInstall      " Install treesitter parsers
:checkhealth    " Verify setup
```

### tmux

**Configuration:** `~/.config/tmux/tmux.conf`

**Key Features:**
- TPM-Redux plugin manager
- OSC 52 clipboard support
- Mouse support
- Sensible defaults
- Yank to system clipboard

**Prefix Key:** `Ctrl+B`

**Keybindings:**
| Key | Action |
|-----|--------|
| `Prefix %` | Split vertically |
| `Prefix "` | Split horizontally |
| `Prefix →` | Next window |
| `Prefix ←` | Previous window |
| `Prefix z` | Zoom pane |
| `Prefix c` | New window |
| `Prefix d` | Detach |
| `Prefix [` | Copy mode |
| `Prefix I` | Install plugins |
| `Prefix U` | Update plugins |

### Oh My Posh

**Configuration:** `~/.config/oh-my-posh/config.json`

**Features:**
- Cross-shell prompt (zsh, bash, fish)
- Git status indicators
- Language version display
- Execution time
- Error status
- Kubernetes context
- AWS profile

---

## Terminal Multiplexer

See [tmux](#tmux) above.

---

## System Monitoring

### btop

**Configuration:** `~/.config/btop/btop.conf`

**Features:**
- CPU, memory, disk, network monitoring
- Process management
- Vim keybindings
- One Dark theme
- Battery status

**Keybindings:**
| Key | Action |
|-----|--------|
| `?` | Help |
| `q` | Quit |
| `1-4` | Switch views |
| `k/j` | Navigate processes |
| `dd` | Kill process |
| `f` | Filter processes |
| `e` | Toggle tree view |
| `m` | Change mode |

### topgrade

**Configuration:** `~/.config/topgrade/topgrade.toml`

**Features:**
- Updates all package managers
- Git repository updates
- Brew, apt, npm, cargo, etc.

**Usage:**
```bash
topgrade          " Run all updates
topgrade --dry-run " Preview what would be updated
```

---

## File Management

### Ranger

**Configuration:** `~/.config/ranger/rc.conf`

**Features:**
- Vim-like keybindings
- File preview
- VCS integration (git status)
- FZF integration

**Keybindings:**
| Key | Action |
|-----|--------|
| `j/k` | Navigate |
| `h/l` | Parent/child directory |
| `Enter` | Open file |
| `r` | Rename |
| `yy` | Copy |
| `dd` | Delete |
| `pp` | Paste |
| `zh` | Toggle hidden files |
| `Space` | Select file |
| `V` | Visual mode |
| `/` | Search |
| `q` | Quit |

**Bookmarks:**
| Key | Location |
|-----|----------|
| `gh` | ~ (home) |
| `gc` | ~/.config |
| `gD` | ~/Downloads |
| `gd` | ~/Documents |

---

## Search Tools

### ripgrep (rg)

**Configuration:** `~/.ripgreprc`

**Features:**
- Fast recursive search
- Respects .gitignore
- Smart case
- Column numbers

**Usage:**
```bash
rg pattern              " Search for pattern
rg -tpy pattern         " Search Python files only
rg -l pattern           " List files with matches
rg --files-with-matches " Files with matches
rg -C 3 pattern         " 3 lines of context
```

### fd

**Features:**
- Fast alternative to `find`
- Respects .gitignore
- Smart case

**Usage:**
```bash
fd pattern              " Find files
fd -e py pattern        " Find Python files
fd -t f pattern         " Find files only
fd -t d pattern         " Find directories only
fd -H pattern           " Include hidden files
```

### fzf

**Configuration:** Shell integration in zsh/bash/fish

**Features:**
- Fuzzy finder
- History search
- File search
- Directory navigation

**Usage:**
```bash
Ctrl+R          " Search history
Ctrl+T          " Search files
Alt+C           " Search directories
**<Tab>         " FZF completion
cat file | fzf  " Interactive filter
```

---

## Version Control

### Git

**Configuration:** `~/.config/git/config`

**Aliases:**
```bash
git co       " checkout
git br       " branch
git ci       " commit
git st       " status
git last     " log -1 HEAD
git unstage  " reset HEAD --
git visual   " !gitk
```

### lazygit

**Configuration:** `~/.config/lazygit/config.yml`

**Features:**
- Terminal UI for git
- Interactive staging
- Branch management
- Merge conflict resolution

**Keybindings:**
| Key | Action |
|-----|--------|
| `?` | Help |
| `q` | Quit |
| `Space` | Stage/unstage |
| `a` | Stage all |
| `c` | Commit |
| `P` | Push |
| `p` | Pull |
| `n` | New branch |
| `d` | Discard changes |
| `D` | Delete |

### gh (GitHub CLI)

**Configuration:** `~/.config/gh/config.yml`

**Features:**
- GitHub operations from CLI
- PR management
- Issue tracking
- Workflow management

**Usage:**
```bash
gh auth login           " Authenticate
gh repo view            " View repository
gh pr list              " List PRs
gh pr create            " Create PR
gh issue list           " List issues
gh workflow list        " List workflows
```

---

## AI Assistants

### Claude Code

**Configuration:** `~/.claude/`

**Features:**
- Personal instructions (CLAUDE.md)
- Skills directory
- Commands directory
- Hooks (RTK token optimization)

**Keybindings:**
```bash
/claude [prompt]        " Send prompt to Claude
Ctrl+Shift+Space        " Quick ask
```

### Codex CLI

**Configuration:** `~/.codex/`

**Features:**
- OpenAI Codex integration
- MCP servers
- AGENTS.md for project context

### OpenCode

**Configuration:** `~/.config/opencode/`

**Features:**
- AI-powered coding assistant
- Custom skills
- Project-specific agents

---

## Prompt Customization

### Oh My Posh

See [Oh My Posh](#oh-my-posh) above.

---

## See Also

- [README.md](./README.md) - Overview and quick start
- [INSTALL.md](./INSTALL.md) - Installation instructions
- [SECURITY.md](./SECURITY.md) - Security and secrets handling
