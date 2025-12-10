zmodload zsh/zprof
export ZSH="$HOME/.oh-my-zsh"

# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="gnzh"

ENABLE_CORRECTION="true"
export FUNCNEST=100

# plugins+=(vi-mode)
plugins=(git zsh-interactive-cd copypath z fzf colorize jsontools)
plugins+=(zsh-vi-mode) # https://github.com/jeffreytse/zsh-vi-mode

source $ZSH/oh-my-zsh.sh

export PATH=$PATH:/opt/tiger/toutiao/lib:/opt/tiger/jdk/jdk1.8/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/tiger/ss_bin:/usr/local/jdk/bin:/usr/sbin/:/opt/tiger/ss_lib/bin:/opt/tiger/ss_lib/python_package/lib/python2.7/site-packages/django/bin:/opt/tiger/yarn_deploy/hadoop/bin/:/opt/tiger/yarn_deploy/hive/bin/:/opt/tiger/yarn_deploy/jdk/bin/:/opt/tiger/hadoop_deploy/jython-2.5.2/bin:/opt/tiger/dev_toolkit/bin:/usr/local/tao/agent/modules/bvc/bin

alias vim='nvim'

source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
bindkey '^j' autosuggest-accept
bindkey '^k' forward-word  #https://github.com/zsh-users/zsh-autosuggestions/issues/265
bindkey '^u' backward-kill-line
bindkey '^p' up-line-or-history
bindkey '^n' down-line-or-history

# export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#ff00ff,bg=cyan,bold,underline"

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
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


# https://bytedance.larkoffice.com/wiki/wikcn9pPaYLxtsxY29OLzY4RgUg
[ -f "$HOME/.bytebm/config/config.sh" ] && . "$HOME/.bytebm/config/config.sh"

. /usr/share/autojump/autojump.sh

export no_proxy=.byteintl.net,.byted.org,.bytedance.net

#export RUNTIME_IDC_NAME=boe
#export RUNTIME_IDC_NAME=boe
#export RUNTIME_IDC_NAME=hl
export RUNTIME_IDC_NAME=lf
export TCE_PSM="ecom.search.stream"
#export TCE_PSM="ecom.search.guide_data_producer"
export CONSUL_HTTP_HOST=10.37.39.172
export CONSUL_HTTP_PORT=2280
export BYTED_HOST_IPV6=::1
export MY_HOST_IPV6=::1
export TCE_STAGE=prod
export IS_TCE_DOCKER_ENV=1
#export SEC_TOKEN_STRING=eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJ2ZXJzaW9uIjowLCJhdXRob3JpdHkiOiJUQ0UiLCJwcmltYXJ5QXV0aFR5cGUiOiJwc20iLCJwc20iOiJlY29tLnNlYXJjaC5zdHJlYW0iLCJ1c2VyIjoicWllc2FpIiwiZXhwaXJlVGltZSI6MTc2MzEwODQzOCwiZXh0ZW5zaW9uIjp7ImNsdXN0ZXJfbmFtZSI6ImRlZmF1bHQiLCJpZGMiOiJMUSIsImxvZ2ljYWxfY2x1c3RlciI6ImRlZmF1bHQiLCJwaHlzaWNhbF9jbHVzdGVyIjoiQnJhaW4iLCJzZXJ2aWNlX3R5cGUiOiJhcHBfZW5naW5lIiwiem9uZSI6IkNoaW5hLU5vcnRoIn19.YOfr59OQfl-OBDogSOzqjez1FKSjeWgLEqR_UEYTmn5mcKET3z8w3TXufD4zeKHl9a7xASYbMb-t_JMAtDV1hyCIf3C7PC9ltTaKm8rqfrYALjc_ctGaSEvG1Knp7zzYgUIcO8XpDntsEctStFVZl1enwJooxK4j0S0icZ4G6iH92KAcXCHZ8dful_kNg2y_tX0Luur71YFpg9BddlESTQlU3ruVX4RvAyGib7C0Zz2oIMfX-CB7T-hp9jGOczfePUBosuvxgnsKfpBSAqbJWnWCVlNiAUjC7r2GdNiflF0FafhkYNlO1qHcYFlQgj56PUxAaSBEIIjImzhJXBJcSg


# export TCE_PSM='life.open.operation_sop'
. /usr/share/autojump/autojump.sh

prompt_context() {
  if [[ "$USER" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
    prompt_segment black default "%(!.%{%F{yellow}%}.)$USER"
  fi
}

# Do the initialization when the script is sourced (i.e. Initialize instantly)
ZVM_INIT_MODE=sourcing

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
eval $(thefuck --alias)
export TLDR_LANG=zh_CN
. "$HOME/.cargo/env"
# zsh启动测速
# zprof

# Added by coco installer
export PATH="/home/lihao.hellohake/.local/bin:$PATH"

export HOME=/data00/home/lihao.hellohake
# 自定义 Prompt 格式
# %n = 用户名
# %~ = 相对路径 (会自动将 $HOME 显示为 ~)
# %{$fg[cyan]%} = 颜色设置
PROMPT='%{$fg[cyan]%}%n%{$reset_color%} %{$fg[blue]%}%~%{$reset_color%} $(git_prompt_info)
$ '
