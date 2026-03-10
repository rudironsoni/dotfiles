# FZF integration for Zsh
# Managed by chezmoi
# https://github.com/junegunn/fzf

# =============================================================================
# FZF Setup
# =============================================================================

# Auto-detect fzf installation
if [[ -d /usr/share/fzf ]]; then
    # System installation (Debian/Ubuntu)
    source /usr/share/fzf/key-bindings.zsh 2>/dev/null
    source /usr/share/fzf/completion.zsh 2>/dev/null
elif [[ -d /usr/share/doc/fzf/examples ]]; then
    # Alternative system path
    source /usr/share/doc/fzf/examples/key-bindings.zsh 2>/dev/null
    source /usr/share/doc/fzf/examples/completion.zsh 2>/dev/null
elif [[ -f /usr/local/opt/fzf/shell/key-bindings.zsh ]]; then
    # Homebrew installation (macOS)
    source /usr/local/opt/fzf/shell/key-bindings.zsh
    source /usr/local/opt/fzf/shell/completion.zsh
elif [[ -f /opt/homebrew/opt/fzf/shell/key-bindings.zsh ]]; then
    # Homebrew installation (Apple Silicon)
    source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
    source /opt/homebrew/opt/fzf/shell/completion.zsh
elif [[ -f ~/.fzf.zsh ]]; then
    # FZF install script
    source ~/.fzf.zsh
fi

# =============================================================================
# FZF Configuration
# =============================================================================

# Default options
export FZF_DEFAULT_OPTS='
    --height 60%
    --layout=reverse
    --border
    --info=inline
    --prompt="∼ "
    --pointer="▶"
    --marker="✓"
    --bind "ctrl-y:preview-up,ctrl-e:preview-down"
    --bind "ctrl-b:preview-page-up,ctrl-f:preview-page-down"
    --bind "ctrl-u:half-page-up,ctrl-d:half-page-down"
    --bind "ctrl-a:select-all+accept"
    --bind "ctrl-r:toggle-sort"
    --bind "?:toggle-preview"
    --preview-window "right:50%:wrap"
'

# Use ripgrep for file search (faster, respects .gitignore)
if command -v rg &> /dev/null; then
    export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*" --glob "!node_modules/*"'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# Use fd for directory search
if command -v fd &> /dev/null; then
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git --exclude node_modules'
fi

# Ctrl-T: File search with preview
export FZF_CTRL_T_OPTS='
    --preview "bat --style=numbers --color=always --line-range=:500 {} 2>/dev/null || cat {} 2>/dev/null || tree -C {}"
    --preview-window "right:60%:wrap"
'

# Alt-C: Directory search with tree preview
export FZF_ALT_C_OPTS='
    --preview "tree -C {} | head -200"
    --preview-window "right:50%:wrap"
'

# Ctrl-R: History search
export FZF_CTRL_R_OPTS='
    --preview "echo {}"
    --preview-window "down:3:wrap"
    --bind "ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort"
'

# =============================================================================
# FZF Functions
# =============================================================================

# fzf with git branch checkout
fzf-git-branch() {
    git branch -a --color=always | grep -v '/HEAD\s' | sort |
    fzf --ansi --multi --tac --preview-window "right:70%" \
        --preview 'git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" $(echo {} | sed s/^..// | cut -d" " -f1) | head -200' |
    sed 's/^..//' | cut -d' ' -f1 |
    sed 's#^remotes/##' |
    xargs -r git checkout
}

# fzf with git log browser
fzf-git-log() {
    git log --graph --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
    fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
        --bind "ctrl-m:execute:echo {} | grep -o '[a-f0-9]\{7\}' | head -1 | xargs -I % sh -c 'git show --color=always % | less -R'" \
        --preview 'echo {} | grep -o "[a-f0-9]\{7\}" | head -1 | xargs -I % git show --color=always % | head -200'
}

# fzf with directory change
fzf-cd() {
    local dir
    dir=$(find ${1:-.} -path '*/\.*' -prune -o -type d -print 2>/dev/null |
          fzf +m) &&
    cd "$dir"
}

# fzf with process kill
fzf-kill() {
    local pid
    pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')

    if [[ -n "$pid" ]]; then
        echo "Killing process $pid..."
        echo "$pid" | xargs kill -${1:-9}
    fi
}

# fzf with environment variables
fzf-env() {
    printenv | fzf --preview "echo {}" --preview-window "down:1:wrap"
}

# fzf with aliases
fzf-alias() {
    alias | fzf --preview "echo {}" --preview-window "down:1:wrap" |
    sed 's/=.*//' | xargs -r alias
}

# =============================================================================
# Aliases
# =============================================================================

# Quick access to fzf functions
alias fbr='fzf-git-branch'
alias fgl='fzf-git-log'
alias fcd='fzf-cd'
alias fkill='fzf-kill'
alias fenv='fzf-env'
alias falias='fzf-alias'

# FZF with bat preview
alias preview='fzf --preview "bat --style=numbers --color=always {}"'
