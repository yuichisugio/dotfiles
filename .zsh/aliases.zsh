# ~/.zsh/aliases.zsh

# ===========================================
# Git Aliases
# ===========================================
alias ga='git add .'
alias gaa='git add --all'
alias gs='git status'
alias gss='git status --short'
alias gc='git commit'
alias gcm='git commit -m'
alias gca='git commit --amend'
alias gpom='git push origin main'
alias gpod='git push origin develop'
alias gpo='git push origin'
alias gpl='git pull'
alias gplom='git pull origin main'
alias gplod='git pull origin develop'
alias gco='git checkout'
alias gcob='git checkout -b'
alias gb='git branch'
alias gba='git branch -a'
alias gbd='git branch -d'
alias gl='git log --oneline --graph --decorate'
alias gla='git log --oneline --graph --decorate --all'
alias gd='git diff'
alias gds='git diff --staged'

# ===========================================
# Navigation Aliases
# ===========================================
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias lh='ls -lh'        # 人間が読みやすい形式でファイルサイズを表示

# ===========================================
# System Aliases
# ===========================================
alias cls='clear'
alias h='history'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# ===========================================
# Development Aliases
# ===========================================
#npm
alias nrd='npm run dev'
alias nrb='npm run build'
alias nrs='npm run start'
alias nrt='npm run test'

# pnpm
alias prd='pnpm run dev'
alias prb='pnpm run build'
alias prs='pnpm run start'
alias prt='pnpm run test'

# yarn用
alias yrd='yarn run dev'
alias yrb='yarn run build'
alias yrs='yarn run start'
alias yrt='yarn run test'

# ===========================================
# Utility Functions（関数形式のエイリアス）
# ===========================================

# ディレクトリを作成して移動
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# ファイルサイズの大きい順にソート
lsize() {
    du -sh * | sort -hr
}

# プロセスを名前で検索
psg() {
    ps aux | grep -v grep | grep "$1"
}

# 指定したポートで動いているプロセスを表示
port() {
    lsof -i :"$1"
}

