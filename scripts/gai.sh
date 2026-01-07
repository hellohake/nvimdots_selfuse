#!/bin/bash

# 颜色定义，用于美化输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

# 1. 检查是否在 git 仓库中
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    error "当前不在 git 仓库中"
    exit 1
fi

# 2. 执行 git add
# 如果用户传递了参数，则使用参数作为 add 的对象；否则默认 git add .
if [ $# -gt 0 ]; then
    info "执行: git add $*"
    git add "$@"
else
    info "执行: git add . (添加所有变动)"
    git add .
fi

if [ $? -ne 0 ]; then
    error "git add 失败"
    exit 1
fi

# 检查是否有暂存的更改
if git diff --cached --quiet; then
    warn "没有需要提交的更改 (No staged changes)"
    exit 0
fi

# 3. 执行 git cco (AI 写评论并提交)
info "执行: git cco (生成评论并提交)..."
git cco
CCO_EXIT=$?

if [ $CCO_EXIT -ne 0 ]; then
    error "git cco 执行失败或被取消"
    exit $CCO_EXIT
fi

# 简单的检查：看刚才是否真的生成了新的 commit
# 这一步不是必须的，但可以防止 cco 没 commit 就跑去 push
# 我们可以检查 HEAD 是否比 @{u} 新，或者只是简单的尝试 push

# 4. 执行 git push
info "执行: git push..."
git push

PUSH_EXIT=$?
if [ $PUSH_EXIT -ne 0 ]; then
    error "git push 失败"
    
    # 尝试分析原因
    # 检查是否是因为远程有更新 (non-fast-forward)
    # 获取 git status 的输出可能有点多余，直接建议用户
    
    echo -e "\n${YELLOW}可能的原因与建议:${NC}"
    echo "1. 远程分支有新的提交 -> 请尝试: ${GREEN}git pull --rebase${NC} 后再次尝试推送"
    echo "2. 网络问题 -> 请检查网络连接"
    echo "3. 权限问题 -> 请检查 git 凭证"
    
    # 询问用户是否要立即拉取 (可选功能，这里保持简单，只提示)
    exit $PUSH_EXIT
fi

success "流程完成: Add -> Cco -> Push"
