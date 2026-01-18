# =============================================================================
# ZSH CONFIGURATION
# =============================================================================

# --- 1. CORE & PERFORMANCE ---

# zmodload zsh/zprof                   # Startup profiling (commented out)
export ZSH="$HOME/.oh-my-zsh"
export FUNCNEST=500                    # Prevent deep recursion
ZSH_DISABLE_COMPFIX="true"             # Skip insecure directories check
ENABLE_CORRECTION="true"               # Command auto-correction

# Smart Completion Initialization (Cache for 24h)
autoload -Uz compinit
_comp_path="$ZSH/cache/zcompdump-$HOST"
setopt localoptions extendedglob
if [[ -n "$_comp_path"(#qN.m-1) ]]; then
    compinit -C -d "$_comp_path"
else
    compinit -i -d "$_comp_path"
fi


# --- 2. THEME & PLUGINS ---

ZSH_THEME="gnzh"

plugins=(
    git
    zsh-interactive-cd
    copypath
    copyfile
    copybuffer
    z
    fzf
    colorize
    jsontools
    zsh-autosuggestions
    zsh-syntax-highlighting
)

# Git performance tuning for large repos
zstyle ':omz:plugins:git' status-ignore-submodules true

source $ZSH/oh-my-zsh.sh


# --- 3. KEYBINDINGS ---

# FZF bindings (Debian/Ubuntu fix)
[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && \
    source /usr/share/doc/fzf/examples/key-bindings.zsh

# Shell navigation
setopt IGNORE_EOF                      # Prevent Ctrl-d exit
bindkey '^j' autosuggest-accept        # Accept suggestion
bindkey '^k' forward-word              # Jump word forward
bindkey '^u' backward-kill-line        # Clear line start
bindkey '^p' up-line-or-history        # Up
bindkey '^n' down-line-or-history      # Down


# --- 4. ENVIRONMENT & PATHS ---

# 4.1 Base System
export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH="$HOME/.local/bin:$PATH"

# 4.2 Development Tools
# Golang
export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"
export GOPATH=$HOME/go
export PATH="$HOME/github_repo/go1.25.5/bin:$PATH"
export GOPLS_SCRIPT="$HOME/start_gopls.sh"

# Neovim & Coco
export PATH="$PATH:$HOME/github_repo/nvim-0.10.4/bin"
export PATH="/data00/home/lihao.hellohake/.local/bin:$PATH"

# Node/NVM
export NVM_DIR="$HOME/.nvm"

# Rust
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# 4.3 Company Environment (Tiger/ByteDance)
export PATH=$PATH:/opt/tiger/toutiao/lib:/opt/tiger/jdk/jdk1.8/bin
export PATH=$PATH:/opt/tiger/ss_bin:/usr/local/jdk/bin:/opt/tiger/ss_lib/bin
export PATH=$PATH:/opt/tiger/ss_lib/python_package/lib/python2.7/site-packages/django/bin
export PATH=$PATH:/opt/tiger/yarn_deploy/hadoop/bin/:/opt/tiger/yarn_deploy/hive/bin/
export PATH=$PATH:/opt/tiger/yarn_deploy/jdk/bin/:/opt/tiger/hadoop_deploy/jython-2.5.2/bin
export PATH=$PATH:/opt/tiger/dev_toolkit/bin:/usr/local/tao/agent/modules/bvc/bin

# 4.4 Business Variables
[ -f "$HOME/.bytebm/config/config.sh" ] && . "$HOME/.bytebm/config/config.sh"
export LANG=zh_CN.UTF-8
export RUNTIME_IDC_NAME=lf
export TCE_PSM="ecom.search.stream"
export CONSUL_HTTP_HOST=10.37.39.172
export CONSUL_HTTP_PORT=2280
export BYTED_HOST_IPV6=::1
export MY_HOST_IPV6=::1
export TCE_STAGE=prod
export IS_TCE_DOCKER_ENV=1
export TLDR_LANG=zh_CN

# 4.5 Network & Proxy
export http_proxy=http://sys-proxy-rd-relay.byted.org:8118
export https_proxy=http://sys-proxy-rd-relay.byted.org:8118
export no_proxy=*.byted.org,.byteintl.net,.bytedance.net

# 4.6 Misc
export TMUX_TMPDIR=~/.tmux/tmp
export FZF_CTRL_T_COMMAND='fd --type f --hidden --follow --exclude .git'
export HOME="/home/lihao.hellohake"    # Fix prompt abbreviation
[ -f /usr/share/autojump/autojump.sh ] && . /usr/share/autojump/autojump.sh


# --- 5. ALIASES ---

alias vim='nvim'
alias gai='~/gai.sh'

# Tmux: Reload config in all panes (Parallel, skip current)
alias sourceall='tmux list-panes -a -F "#{pane_id} #{pane_current_command}" | \
    grep -E "zsh$|bash$|sh$" | \
    grep -v "^$(tmux display-message -p "#D") " | \
    awk "{print \$1}" | \
    xargs -P 4 -I {} tmux send-keys -t {} "SKIP_SYNC=1 source ~/.zshrc" Enter'

# Gopls Management
alias gostart='pgrep -f "gopls serve" >/dev/null && echo "⚠️  Gopls ALREADY running." || (nohup "$GOPLS_SCRIPT" >/dev/null 2>&1 & echo "🚀 Gopls Started!")'
alias gostop='pkill -9 -f "gopls serve"; rm -f /dev/shm/gopls-daemon-*.sock; echo "🛑 Gopls Killed!"'
alias gorestart='gostop; sleep 1; nohup "$GOPLS_SCRIPT" >/dev/null 2>&1 & echo "♻️  Gopls Restarted!"'
alias gostatus='ps -eo pid,user,%cpu,%mem,cmd | grep "gopls serve" | grep -v grep || echo "🔴 gopls NOT running."'


# --- 6. FUNCTIONS ---

# 6.1 Tools & Helpers
Proxy() {
    local ip=${SSH_CLIENT/ */}
    if [ "$1" == "on" ]; then
        export https_proxy=$ip:8118; export http_proxy=$ip:8118
        echo "Proxy On ($ip:8118)"
    else
        unset https_proxy; unset http_proxy
        echo "Proxy Off"
    fi
}

coco() { python3 ~/.local/bin/coco_wrapper.py "$@"; }

copygit() {
    local branch=$(git branch --show-current 2>/dev/null)
    [ -z "$branch" ] && { echo "Not a git repo."; return 1; }
    local encoded=$(printf "%s" "$branch" | base64 | tr -d '\n')
    [ -n "$TMUX" ] && printf "\033Ptmux;\033\033]52;c;%s\a\033\\" "$encoded" || printf "\033]52;c;%s\a" "$encoded"
    echo "Branch '$branch' copied."
}

# 6.2 Worktree Management (gw-add)
gw-init-links() {
    echo "🔗 Linking shared configs..."
    for f in .coco .ai_doc AGENTS.md; do
        [ -e "../$f" ] && ln -sfn "../$f" "./$f" && echo "  ✅ $f" || echo "  ⚠️  ../$f missing"
    done
}

gw-add() {
    local branch="" base="" dirname=""
    show_help() { echo "Usage: gw-add <branch> [base] [-d dir]"; }

    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help) show_help; return 0 ;;
            -d|--dir) dirname="$2"; shift 2 ;;
            *) [ -z "$branch" ] && branch="$1" || ([ -z "$base" ] && base="$1" || ([ -z "$dirname" ] && dirname="$1")); shift ;;
        esac
    done

    [ -z "$branch" ] && { show_help; return 1; }
    [ -z "$dirname" ] && dirname="$branch"

    local target_dir="../$dirname"
    [[ "$dirname" == /* || "$dirname" == ./* || "$dirname" == *../* ]] && { echo "Error: Invalid path."; return 1; }
    
    # Root handling
    [ ! -e "../.coco" ] && [ -e "./.coco" ] && [[ "$target_dir" == ../* ]] && target_dir="./${dirname}"

    echo "🌲 Setup '$branch' in '$target_dir'..."
    
    if [ -n "$base" ]; then
        [[ "$base" == "main" ]] && ! git rev-parse --verify "$base" >/dev/null 2>&1 && \
            git rev-parse --verify "master" >/dev/null 2>&1 && base="master"
        
        if git rev-parse --verify "$branch" >/dev/null 2>&1; then
            echo "⚠️  Branch exists, checkout only."
            git worktree add "$target_dir" "$branch" || return 1
        else
            git worktree add -b "$branch" "$target_dir" "$base" || return 1
        fi
    else
        git worktree add "$target_dir" "$branch" || { echo "❌ Failed."; return 1; }
    fi

    echo "📂 Entering..."; cd "$target_dir" || return 1
    gw-init-links
    echo "🚀 Ready: $(pwd)"
}

# 6.3 Config Sync
sync_cfg() {
    [[ -n "$SKIP_SYNC" ]] && return
    local t_dir="$HOME/.config/nvim/lua/user/sys_cfg"
    local s_dir="$HOME/.config/nvim/scripts"
    [ ! -d "$t_dir" ] && return

    [[ ~/.zshrc -nt "$t_dir/.zshrc" ]] && cp ~/.zshrc "$t_dir/.zshrc"
    [[ ~/.tmux.conf -nt "$t_dir/.tmux.conf" ]] && cp ~/.tmux.conf "$t_dir/.tmux.conf"
    [ -f "$HOME/start_gopls.sh" ] && [[ "$HOME/start_gopls.sh" -nt "$t_dir/start_gopls.sh" ]] && cp "$HOME/start_gopls.sh" "$t_dir/start_gopls.sh"
    [ -f "$HOME/gai.sh" ] && [ -d "$s_dir" ] && [[ "$HOME/gai.sh" -nt "$s_dir/gai.sh" ]] && cp "$HOME/gai.sh" "$s_dir/gai.sh"
}
sync_cfg # Run on startup


# --- 7. LAZY LOADING ---

# NVM Lazy
_load_nvm() {
    unset -f nvm node npm npx
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
}
for cmd in nvm node npm npx; do eval "$cmd() { _load_nvm; $cmd \"\$@\"; }"; done

# Eval Cache (Brew/TheFuck)
if [[ -z "$_CFG_SYNCED" ]]; then
    _brew_cache="$HOME/.cache/zsh_brew_cache"
    if [[ -f "$_brew_cache" ]]; then source "$_brew_cache"
    else mkdir -p "$HOME/.cache"; /home/linuxbrew/.linuxbrew/bin/brew shellenv > "$_brew_cache" 2>/dev/null; source "$_brew_cache"; fi
    
    fuck() {
        TF_PYTHONIOENCODING=$PYTHONIOENCODING; export TF_SHELL=zsh; export TF_ALIAS=fuck
        TF_SHELL_ALIASES=$(alias); export TF_SHELL_ALIASES; TF_HISTORY="$(fc -ln -10)"; export TF_HISTORY
        export PYTHONIOENCODING=utf-8; TF_CMD=$(thefuck THEFUCK_ARGUMENT_PLACEHOLDER $@) && eval $TF_CMD
        unset TF_HISTORY; export PYTHONIOENCODING=$TF_PYTHONIOENCODING; test -n "$TF_CMD" && print -s $TF_CMD
    }
fi
export _CFG_SYNCED=1


# --- 8. PROMPT & FINALIZATION ---

prompt_context() {
  [[ "$USER" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]] && prompt_segment black default "%(!.%{%F{yellow}%}.)$USER"
}
PROMPT='%{$fg[cyan]%}%n%{$reset_color%} %{$fg[blue]%}%40<..<%~%<<%{$reset_color%} $(git_prompt_info) %{$fg[green]%}[%*]%{$reset_color%}
$ '

ZVM_INIT_MODE=sourcing
