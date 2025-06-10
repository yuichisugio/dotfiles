# ===========================================
# Zsh Core Configuration
# ===========================================
setopt AUTO_CD              # ディレクトリ名だけでcdする
setopt CORRECT              # コマンドのタイポを修正
setopt HIST_IGNORE_DUPS     # 重複するコマンドは履歴に保存しない
setopt HIST_IGNORE_SPACE    # スペースで始まるコマンドは履歴に保存しない
setopt SHARE_HISTORY        # 履歴を他のシェルとリアルタイムで共有
setopt HIST_REDUCE_BLANKS
setopt APPEND_HISTORY       # 履歴を追記する
setopt EXTENDED_HISTORY     # 実行時間も記録する

#履歴の設定
HISTFILE=~/.zsh_history     # 履歴ファイルの場所
HISTSIZE=10000              # メモリ上の履歴数
SAVEHIST=10000              # ファイルに保存する履歴数

# 補完の設定
autoload -U compinit        # 補完機能を有効化
compinit -i                 # 安全でないファイルを無視して初期化
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'     # 大文字小文字を区別しない補完
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}   # 補完候補に色を付ける


# ===========================================
# Completion Configuration
# ===========================================

# 補完機能の初期化
autoload -U compinit
compinit -i                   # セキュリティチェックを無視して初期化

# 補完の詳細設定
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'  # 大文字小文字を区別しない
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS} # ls風の色分け
zstyle ':completion:*' menu select                    # 補完候補をメニューで選択可能
zstyle ':completion:*:descriptions' format '%B%d%b'   # 説明文を太字で表示
zstyle ':completion:*:warnings' format 'No matches: %d' # マッチしない場合の表示


# ===========================================
# Colors and Syntax Highlighting
# ===========================================

# 色の有効化
autoload -U colors && colors

# プロンプトの色分け設定
export PS1="%{$fg[cyan]%}%1~%{$reset_color%} %{$fg[green]%}%#%{$reset_color%} "

# zsh-syntax-highlightingのインストールと設定
# Homebrewでインストール: brew install zsh-syntax-highlighting
if [[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
    source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    
    # シンタックスハイライトの色設定
    ZSH_HIGHLIGHT_STYLES[command]='fg=green,bold'           # コマンド名を緑色の太字
    ZSH_HIGHLIGHT_STYLES[alias]='fg=magenta,bold'           # エイリアスを紫色の太字
    ZSH_HIGHLIGHT_STYLES[builtin]='fg=yellow,bold'          # 組み込みコマンドを黄色の太字
    ZSH_HIGHLIGHT_STYLES[function]='fg=blue,bold'           # 関数を青色の太字
    ZSH_HIGHLIGHT_STYLES[command-substitution]='fg=cyan'    # コマンド置換をシアン色
    ZSH_HIGHLIGHT_STYLES[path]='fg=white,underline'         # パスを白色の下線付き
    ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=cyan'    # 短いオプション(-v)をシアン色
    ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=cyan'    # 長いオプション(--version)をシアン色
fi

source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# lsコマンドの色分け（macOS用）
export CLICOLOR=1
export LSCOLORS=ExFxCxDxBxegedabagacad

# grepの色分け
export GREP_OPTIONS='--color=auto'
export GREP_COLOR='1;32'


# ===========================================
# PATH Configuration
# ===========================================

# Homebrewのパス設定
export PATH="/opt/homebrew/bin:$PATH"

# ターミナルに表示する%の部分を、カレントディレクトリPATHのみ表示して、usernameなどの表示は無しにする
export PS1="%~ $ "

export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" && export PATH="/usr/local/node20-arm64/bin:$PATH" && export PNPM_HOME="/Users/yuichi.sugio/Library/pnpm" && export PATH="$PNPM_HOME:$PATH"

# ===========================================
# Development Tools Configuration
# ===========================================

# Node.js (nvm) の設定
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                    # nvmスクリプトの読み込み
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # nvm補完機能の読み込み

# pnpm の設定
export PNPM_HOME="/Users/sugioyuuichi/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;                                             # 既にパスに含まれている場合は何もしない
  *) export PATH="$PNPM_HOME:$PATH" ;;                             # パスに追加
esac

# ===========================================
# Python/Conda Configuration
# ===========================================

# >>> conda initialize >>>
# Anacondaの初期化設定（conda initによって自動生成）
__conda_setup="$('/Users/sugioyuuichi/opt/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"                                          # conda hookが成功した場合の処理
else
    # フォールバック処理
    if [ -f "/Users/sugioyuuichi/opt/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/sugioyuuichi/opt/anaconda3/etc/profile.d/conda.sh"  # conda.shを直接読み込み
    else
        export PATH="/Users/sugioyuuichi/opt/anaconda3/bin:$PATH"     # パスに直接追加
    fi
fi
unset __conda_setup                                                # 一時変数をクリーンアップ
# <<< conda initialize <<<

# ===========================================
# Aliases and Functions
# ===========================================

# エイリアス設定ファイルの読み込み
if [[ -f ~/.zsh/aliases.zsh ]]; then
    source ~/.zsh/aliases.zsh
else
    echo "Warning: ~/.zsh/aliases.zsh not found"
fi

# ===========================================
# Additional Configurations
# ===========================================

# 環境固有の設定ファイル（存在する場合のみ読み込み）
if [[ -f ~/.zshrc.local ]]; then
    source ~/.zshrc.local
fi

# プロジェクト固有の設定（存在する場合のみ読み込み）
if [[ -f ~/.zsh/projects.zsh ]]; then
    source ~/.zsh/projects.zsh
fi


# ===========================================
# Plugin
# ===========================================
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# ===========================================
# SSH
# ===========================================

# SSH Agent自動起動設定
if [ -z "$SSH_AUTH_SOCK" ]; then
  eval $(ssh-agent -s)
  ssh-add --apple-use-keychain ~/.ssh/id_ed25519
fi
