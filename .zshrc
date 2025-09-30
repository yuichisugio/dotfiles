# ===========================================
# Zsh WSL Compatible
# ===========================================

fpath=(path/to/zsh-completions/src $fpath)

# Cursor Agent Mode detection (最初に実行)
if [[ "$AGENT_MODE" == "true" ]] || [[ "$TERM_PROGRAM" == "vscode" && -z "$CURSOR_ENABLED" ]]; then
  # Disable complex prompt features for AI agents and VS Code (but not Cursor)
  ZSH_THEME=""        # Disable Powerlevel10k
  PROMPT='%n@%m:%~%# '  # 最小限のプロンプト
  POWERLEVEL9K_INSTANT_PROMPT=off
  # Ensure non-interactive mode
  export DEBIAN_FRONTEND=noninteractive
  export NONINTERACTIVE=1
else
  # Enable Powerlevel10k instant prompt only when not in agent mode
  if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
  fi
fi

# 環境検出
detect_environment() {
    if [[ -f /proc/sys/fs/binfmt_misc/WSLInterop ]]; then
        echo "wsl"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux"* ]]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

ENVIRONMENT=$(detect_environment)

# WSL固有の設定
if [[ "$ENVIRONMENT" == "wsl" ]]; then
    # WSLでWindows側のパスを追加（VS Code、Cursorなどのため）
    export PATH="$PATH:/mnt/c/Windows/System32"
    export PATH="$PATH:/mnt/c/Windows"
    
    # WSL2の場合のX11フォワーディング設定（GUI アプリケーション用）
    if [[ -n "$WSL_DISTRO_NAME" ]]; then
        export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0
        export LIBGL_ALWAYS_INDIRECT=1
    fi
    
    # Windowsのホームディレクトリへのエイリアス
    export WINHOME="/mnt/c/Users/$(whoami)"
fi

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
# 色の有効化

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
autoload -U colors && colors

# プロンプトの色分け設定
export PS1="%{$fg[cyan]%}%1~%{$reset_color%} %{$fg[green]%}%#%{$reset_color%} "

# 環境別のシンタックスハイライト設定（Agent Modeでない場合のみ）
# Cursor環境でも有効にするため、より厳密な条件に変更
if [[ "$AGENT_MODE" != "true" ]] && [[ ! ("$TERM_PROGRAM" == "vscode" && -z "$CURSOR_ENABLED") ]]; then
    case "$ENVIRONMENT" in
        "macos")
            # Homebrewでインストール: brew install zsh-syntax-highlighting
            if [[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
                source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
            fi
            
            # zsh-autosuggestions (macOS)
            if [[ -f $(brew --prefix 2>/dev/null)/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
                source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
            fi
            
            # zsh-autosuggestions色設定（白い背景でも見やすい色に）
            export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8"
            ;;
        
        "wsl"|"linux")
            # APTでインストール: sudo apt install zsh-syntax-highlighting
            if [[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
                source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
            # 手動インストール版
            elif [[ -f ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
                source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
            elif [[ -f /home/sugio/code/dotfiles/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
                source /home/sugio/code/dotfiles/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
            fi
            
            # zsh-autosuggestions (Linux/WSL)
            if [[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
                source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
            # 手動インストール版
            elif [[ -f ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
                source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
            elif [[ -f /home/sugio/code/dotfiles/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
                source /home/sugio/code/dotfiles/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
            fi
            
            # zsh-completions (Linux/WSL)
            if [[ -f ~/.zsh/plugins/zsh-completions/zsh-completions.plugin.zsh ]]; then
                source ~/.zsh/plugins/zsh-completions/zsh-completions.plugin.zsh
            elif [[ -f /home/sugio/code/dotfiles/.zsh/plugins/zsh-completions/zsh-completions.plugin.zsh ]]; then
                source /home/sugio/code/dotfiles/.zsh/plugins/zsh-completions/zsh-completions.plugin.zsh
            fi
            
            # zsh-autosuggestions色設定（白い背景でも見やすい色に）
            export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8"
            ;;
    esac
fi

# シンタックスハイライトの共通色設定
if [[ -n "$ZSH_HIGHLIGHT_STYLES" ]]; then
    ZSH_HIGHLIGHT_STYLES[command]='fg=green,bold'           # コマンド名を緑色の太字
    ZSH_HIGHLIGHT_STYLES[alias]='fg=magenta,bold'           # エイリアスを紫色の太字
    ZSH_HIGHLIGHT_STYLES[builtin]='fg=yellow,bold'          # 組み込みコマンドを黄色の太字
    ZSH_HIGHLIGHT_STYLES[function]='fg=blue,bold'           # 関数を青色の太字
    ZSH_HIGHLIGHT_STYLES[command-substitution]='fg=cyan'    # コマンド置換をシアン色
    ZSH_HIGHLIGHT_STYLES[path]='fg=white,underline'         # パスを白色の下線付き
    ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=cyan'    # 短いオプション(-v)をシアン色
    ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=cyan'    # 長いオプション(--version)をシアン色
fi

# lsコマンドの色分け
export CLICOLOR=1
if [[ "$ENVIRONMENT" == "macos" ]]; then
    export LSCOLORS=ExFxCxDxBxegedabagacad
else
    # Linux/WSL用のLS_COLORS設定
    export LS_COLORS='di=1;34:ln=1;35:so=1;32:pi=1;33:ex=1;31:bd=34;46:cd=34;43:su=0;41:sg=0;46:tw=0;42:ow=0;43:'
fi

# grepの色分け
export GREP_OPTIONS='--color=auto'
export GREP_COLOR='1;32'


# ===========================================
# PATH Configuration
# ===========================================
# 環境別のPATH設定
case "$ENVIRONMENT" in
    "macos")
        # Homebrewのパス設定
        export PATH="/opt/homebrew/bin:$PATH"
        ;;
    
    "wsl")
        # WSL環境でのPATH設定
        # Linux側のローカルbinを優先
        export PATH="$HOME/.local/bin:$PATH"
        export PATH="/usr/local/bin:$PATH"
        
        # Windows側のVS Code/Cursorへのパス（必要に応じて）
        if [[ -d "/mnt/c/Program Files/Microsoft VS Code/bin" ]]; then
            export PATH="$PATH:/mnt/c/Program Files/Microsoft VS Code/bin"
        fi
        
        # Windows側のユーザーローカルのVS Code
        if [[ -d "/mnt/c/Users/$(whoami)/AppData/Local/Programs/Microsoft VS Code/bin" ]]; then
            export PATH="$PATH:/mnt/c/Users/$(whoami)/AppData/Local/Programs/Microsoft VS Code/bin"
        fi
        ;;
    
    "linux")
        # 通常のLinux環境
        export PATH="$HOME/.local/bin:$PATH"
        export PATH="/usr/local/bin:$PATH"
        ;;
esac

# ===========================================
# Development Tools Configuration
# ===========================================
# Node.js (nvm) の設定 - 全環境共通
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                    # nvmスクリプトの読み込み
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # nvm補完機能の読み込み

# pnpm の設定
if [[ "$ENVIRONMENT" == "macos" ]]; then
    export PNPM_HOME="/Users/$(whoami)/Library/pnpm"
else
    # Linux/WSL環境
    export PNPM_HOME="$HOME/.local/share/pnpm"
fi

case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;                                             # 既にパスに含まれている場合は何もしない
  *) export PATH="$PNPM_HOME:$PATH" ;;                             # パスに追加
esac

# ===========================================
# WSL固有のユーティリティ関数
# ===========================================

if [[ "$ENVIRONMENT" == "wsl" ]]; then
    # Windows側のパスをWSLパスに変換
    winpath() {
        echo "$1" | sed -e 's|\\|/|g' -e 's|^\([A-Za-z]\):|/mnt/\L\1|'
    }
    
    # WSLパスをWindows側のパスに変換
    wslpath() {
        echo "$1" | sed -e 's|^/mnt/\([a-z]\)/|\U\1:\\|' -e 's|/|\\|g'
    }
    
    # Windows側のエクスプローラーで現在のディレクトリを開く
    explorer() {
        if [[ $# -eq 0 ]]; then
            /mnt/c/Windows/explorer.exe "$(wslpath $(pwd))"
        else
            /mnt/c/Windows/explorer.exe "$(wslpath $1)"
        fi
    }
    
    # Windows側のVS Codeで開く
    vscode() {
        if command -v code.exe &> /dev/null; then
            code.exe "$@"
        else
            echo "VS Code is not installed or not in PATH"
        fi
    }
fi

# ===========================================
# Aliases and Functions
# ===========================================

# エイリアス設定ファイルの読み込み
if [[ -f ~/.zsh/aliases.zsh ]]; then
    source ~/.zsh/aliases.zsh
else
    echo "Warning: ~/.zsh/aliases.zsh not found"
fi

# WSL固有のエイリアス
if [[ "$ENVIRONMENT" == "wsl" ]]; then
    alias clip='/mnt/c/Windows/System32/clip.exe'  # クリップボードへのコピー
    alias winhome='cd $WINHOME'                    # Windowsホームディレクトリへ移動
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
# SSH
# ===========================================

# SSH Agentはkeychainを優先し、利用できない場合はssh-agentにフォールバック
if command -v keychain &> /dev/null; then
    eval "$(keychain --eval --quiet --agents ssh id_ed25519 2>/dev/null)"
else
    if [[ -z "$SSH_AUTH_SOCK" ]]; then
        eval "$(ssh-agent -s)"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            ssh-add --apple-use-keychain ~/.ssh/id_ed25519 2>/dev/null || ssh-add ~/.ssh/id_ed25519 2>/dev/null || true
        else
            ssh-add ~/.ssh/id_ed25519 2>/dev/null || true
        fi
    fi
fi

# npmグローバルパッケージのパス
export PATH=~/.npm-global/bin:$PATH

# ~/.local/bin を PATH に追加（重複防止）
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
fi

# Cursor 
export PATH="$PATH:/mnt/c/Users/<USER_NAME>/AppData/Local/Programs/cursor/resources/app/bin"

# Cursor 
export PATH="$PATH:/mnt/c/Users/sugio/AppData/Local/Programs/cursor/resources/app/bin"

# Cursor環境での自動補完を有効にする
if [[ "$TERM_PROGRAM" == "vscode" && ( -n "$VSCODE_IPC_HOOK_CLI" && "$VSCODE_IPC_HOOK_CLI" == *"cursor"* || -d "$HOME/.cursor-server" ) ]]; then
    export CURSOR_ENABLED=1
fi

# Cursor環境でのプラグイン強制読み込み（上記の条件分岐で読み込まれない場合のフォールバック）
if [[ "$CURSOR_ENABLED" == "1" ]]; then
    # zsh-autosuggestions (Linux/WSL)
    if [[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
        source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    # 手動インストール版
    elif [[ -f ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
        source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
    elif [[ -f /home/sugio/code/dotfiles/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
        source /home/sugio/code/dotfiles/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
    fi
    
    # zsh-syntax-highlighting (Linux/WSL)
    if [[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
        source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    # 手動インストール版
    elif [[ -f ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
        source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    elif [[ -f /home/sugio/code/dotfiles/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
        source /home/sugio/code/dotfiles/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    fi
    
    # zsh-autosuggestions色設定（白い背景でも見やすい色に）
    export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8"
fi
