zmodload zsh/zprof
export ZSH="$HOME/.oh-my-zsh"

# -------------------------------------------------------------------
# 性能优化：快速补全初始化 (compinit 优化)
# -------------------------------------------------------------------
# 每天只进行一次完整的 compinit 检查，其余时间使用缓存 (-C)
autoload -Uz compinit
_comp_path="$ZSH/cache/zcompdump-$HOST"
if [[ -n "$_comp_path(#qN.m-1)" ]]; then
    compinit -C -d "$_comp_path"
else
    compinit -i -d "$_comp_path"
fi
ZSH_DISABLE_COMPFIX="true"

# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="gnzh"

ENABLE_CORRECTION="true"
export FUNCNEST=500

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

source $ZSH/oh-my-zsh.sh

# 手动关联 fzf 快捷键 (解决 Debian/Ubuntu 下 OMZ fzf 插件可能失效的问题)
if [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]; then
    source /usr/share/doc/fzf/examples/key-bindings.zsh
fi

export PATH=$PATH:/opt/tiger/toutiao/lib:/opt/tiger/jdk/jdk1.8/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/tiger/ss_bin:/usr/local/jdk/bin:/usr/sbin/:/opt/tiger/ss_lib/bin:/opt/tiger/ss_lib/python_package/lib/python2.7/site-packages/django/bin:/opt/tiger/yarn_deploy/hadoop/bin/:/opt/tiger/yarn_deploy/hive/bin/:/opt/tiger/yarn_deploy/jdk/bin/:/opt/tiger/hadoop_deploy/jython-2.5.2/bin:/opt/tiger/dev_toolkit/bin:/usr/local/tao/agent/modules/bvc/bin

alias vim='nvim'

# 复制 Git 当前分支名到本地剪贴板 (针对 SSH + tmux 优化)
copygb() {
    local branch=$(git branch --show-current 2>/dev/null)
    if [ -z "$branch" ]; then
        echo "Not in a git repository."
        return 1
    fi

    # 确保 base64 没有任何换行符
    local encoded=$(printf "%s" "$branch" | base64 | tr -d '\n')
    
    if [ -n "$TMUX" ]; then
        # tmux 封装：\033Ptmux;\033 是开始，\a\033\\ 是结束
        # 内部是标准的 OSC 52 序列
        printf "\033Ptmux;\033\033]52;c;%s\a\033\\" "$encoded"
    else
        # 标准模式
        printf "\033]52;c;%s\a" "$encoded"
    fi

    echo "Branch '$branch' copied to local clipboard."
}

# 自动同步配置文件到 nvim 仓库供 Git 管理
sync_cfg() {
    local target_dir="$HOME/.config/nvim/lua/user/sys_cfg"
    if [ -d "$target_dir" ]; then
        cp ~/.zshrc "$target_dir/.zshrc"
        cp ~/.tmux.conf "$target_dir/.tmux.conf"
        [ -f "$HOME/start_gopls.sh" ] && cp "$HOME/start_gopls.sh" "$target_dir/start_gopls.sh"
    fi
}
# 启动或 source 时自动执行同步
sync_cfg

# -------------------------------------------------------------------
# 快捷键配置 (插件已通过 Oh My Zsh 自动加载)
# -------------------------------------------------------------------
bindkey '^j' autosuggest-accept
bindkey '^k' forward-word
bindkey '^u' backward-kill-line
bindkey '^p' up-line-or-history
bindkey '^n' down-line-or-history

# 让所有 tmux 面板重新加载 zsh 配置 (自动避开 vim/top 等非 shell 程序，且跳过当前面板)
alias sourceall='tmux list-panes -a -F "#{pane_id} #{pane_current_command}" | grep -E "zsh$|bash$|sh$" | grep -v "^$(tmux display-message -p "#D") " | awk "{print \$1}" | xargs -I {} tmux send-keys -t {} "source ~/.zshrc" Enter'

export http_proxy=http://sys-proxy-rd-relay.byted.org:8118  https_proxy=http://sys-proxy-rd-relay.byted.org:8118  no_proxy=*.byted.org
function Proxy() {
	ip=${SSH_CLIENT/ */}
	if [ "$1" == "on" ]; then
		export https_proxy=$ip:8118
		export http_proxy=$ip:8118
		echo Proxy On
	else
		unset https_proxy
		unset http_proxy
		echo Proxy Off
	fi
}

#export PATH="$PATH:/home/lihao.hellohake/github_repo/nvim-linux64-0.9.5/bin"
export PATH="$PATH:/home/lihao.hellohake/github_repo/nvim-0.10.4/bin"

# go配置
export PATH="$PATH:/usr/local/go/bin:/home/lihao.hellohake/go/bin"
export GOPATH=$HOME/go
# 不用指定版本时、移除指定的环境变量 https://unix.stackexchange.com/questions/108873/removing-a-directory-from-path#comment167586_108876
# PATH=$(echo "$PATH" | sed -e 's|:/home/lihao.hellohake/github_repo/go1.20.14/bin||')
# export PATH=/home/lihao.hellohake/github_repo/go1.20.14/bin:$PATH
export PATH="/home/lihao.hellohake/github_repo/go1.25.5/bin:$PATH"
# gopls配置 for 性能
# pgrep -af gopls
export GOPLS_SCRIPT="$HOME/start_gopls.sh"
alias gostart='pgrep -f "gopls serve" > /dev/null && echo "⚠️  Gopls is ALREADY running (PID: $(pgrep -f "gopls serve" | head -1)). Use gorestart if needed." || (nohup "$GOPLS_SCRIPT" > /dev/null 2>&1 & echo "🚀 Gopls Service Started!")'
alias gostop='pkill -9 -f "gopls serve"; rm -f /dev/shm/gopls-daemon-*.sock; echo "🛑 Gopls Service Killed & Socket Cleaned!"'
alias gorestart='gostop; sleep 1; nohup "$GOPLS_SCRIPT" > /dev/null 2>&1 & echo "♻️  Gopls Service Restarted!"'
alias gostatus='ps -eo pid,user,%cpu,%mem,cmd | grep "gopls serve" | grep -v grep || echo "🔴 gopls 未运行 (No running process). 请执行 [ gostart ] 启动服务."'

export TMUX_TMPDIR=~/.tmux/tmp
#export PATH="$PATH:/home/lihao.hellohake/node_modules/tree-sitter-cli"
# -------------------------------------------------------------------
# 性能优化：NVM 懒加载
# -------------------------------------------------------------------
export NVM_DIR="$HOME/.nvm"
_load_nvm() {
    unset -f nvm node npm npx
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
}
nvm() { _load_nvm; nvm "$@" }
node() { _load_nvm; node "$@" }
npm() { _load_nvm; npm "$@" }
npx() { _load_nvm; npx "$@" }

# -------------------------------------------------------------------
# 性能优化：环境变量与 eval 缓存 (仅在初次 source 时加载)
# -------------------------------------------------------------------
if [[ -z "$_CFG_SYNCED" ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    eval $(thefuck --alias)
fi
export _CFG_SYNCED=1

# --- 恢复环境变量 ---
[ -f "$HOME/.bytebm/config/config.sh" ] && . "$HOME/.bytebm/config/config.sh"
export LANG=zh_CN.UTF-8
export FZF_CTRL_T_COMMAND='fd --type f --hidden --follow --exclude .git'
export no_proxy=.byteintl.net,.byted.org,.bytedance.net
export RUNTIME_IDC_NAME=lf
export TCE_PSM="ecom.search.stream"
export CONSUL_HTTP_HOST=10.37.39.172
export CONSUL_HTTP_PORT=2280
export BYTED_HOST_IPV6=::1
export MY_HOST_IPV6=::1
export TCE_STAGE=prod
export IS_TCE_DOCKER_ENV=1
. /usr/share/autojump/autojump.sh

prompt_context() {
  if [[ "$USER" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
    prompt_segment black default "%(!.%{%F{yellow}%}.)$USER"
  fi
}
ZVM_INIT_MODE=sourcing
# --------------------

export TLDR_LANG=zh_CN
. "$HOME/.cargo/env"
# zsh启动测速
# zprof

# 修正 HOME 路径以确保 %~ 能正确缩写路径 (设置为物理路径以匹配 pwd)
export HOME="/data00/home/lihao.hellohake"

# 自定义 Prompt 格式
# %n = 用户名, %~ = 相对路径, %* = 时间, %D{%Y-%m-%d} = 年月日
PROMPT='%{$fg[cyan]%}%n%{$reset_color%} %{$fg[blue]%}%~%{$reset_color%} $(git_prompt_info) %{$fg[green]%}[%D{%Y-%m-%d} %*]%{$reset_color%}
$ '

# Added by trae-gopls installer
export PATH="$HOME/.local/bin:$PATH"

# Added by coco installer
export PATH="/data00/home/lihao.hellohake/.local/bin:$PATH"
