#!/bin/bash

# dotfiles管理用のインストールスクリプト
# 新しいマシンでの開発環境セットアップを自動化

set -e  # エラーが発生した場合にスクリプトを停止

# カラー出力用の定数定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ログ出力関数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# OSの検出
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

# VSCode設定のシンボリックリンク作成
setup_vscode() {
    local os=$(detect_os)
    local vscode_dir
    
    case $os in
        "macos")
            vscode_dir="$HOME/Library/Application Support/Code/User"
            ;;
        "linux")
            vscode_dir="$HOME/.config/Code/User"
            ;;
        "windows")
            vscode_dir="$APPDATA/Code/User"
            ;;
        *)
            log_error "Unsupported OS: $os"
            return 1
            ;;
    esac
    
    log_info "Setting up VSCode configuration..."
    
    # 既存設定のバックアップ
    if [ -f "$vscode_dir/settings.json" ]; then
        log_warn "Backing up existing VSCode settings..."
        mv "$vscode_dir/settings.json" "$vscode_dir/settings.json.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # シンボリックリンクの作成
    ln -sf "$PWD/vscode/settings.json" "$vscode_dir/settings.json"
    ln -sf "$PWD/vscode/keybindings.json" "$vscode_dir/keybindings.json"
    ln -sf "$PWD/vscode/extensions.json" "$vscode_dir/extensions.json"
    
    log_info "VSCode configuration linked successfully"
}

# Cursor設定のシンボリックリンク作成
setup_cursor() {
    local os=$(detect_os)
    local cursor_dir
    
    case $os in
        "macos")
            cursor_dir="$HOME/Library/Application Support/Cursor/User"
            ;;
        "linux")
            cursor_dir="$HOME/.config/Cursor/User"
            ;;
        "windows")
            cursor_dir="$APPDATA/Cursor/User"
            ;;
        *)
            log_error "Unsupported OS: $os"
            return 1
            ;;
    esac
    
    log_info "Setting up Cursor configuration..."
    
    # ディレクトリが存在しない場合は作成
    mkdir -p "$cursor_dir"
    
    # 既存設定のバックアップ
    if [ -f "$cursor_dir/settings.json" ]; then
        log_warn "Backing up existing Cursor settings..."
        mv "$cursor_dir/settings.json" "$cursor_dir/settings.json.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # シンボリックリンクの作成
    ln -sf "$PWD/cursor/settings.json" "$cursor_dir/settings.json"
    ln -sf "$PWD/cursor/keybindings.json" "$cursor_dir/keybindings.json"
    
    log_info "Cursor configuration linked successfully"
}

# Git設定のセットアップ
setup_git() {
    log_info "Setting up Git configuration..."
    
    # 既存設定のバックアップ
    if [ -f "$HOME/.gitconfig" ]; then
        log_warn "Backing up existing Git configuration..."
        mv "$HOME/.gitconfig" "$HOME/.gitconfig.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # シンボリックリンクの作成
    ln -sf "$PWD/git/.gitconfig" "$HOME/.gitconfig"
    ln -sf "$PWD/git/.gitignore_global" "$HOME/.gitignore_global"
    
    log_info "Git configuration linked successfully"
}

# メイン実行関数
main() {
    log_info "Starting dotfiles installation..."
    
    # 各設定のセットアップを実行
    setup_vscode
    setup_cursor
    setup_git
    
    log_info "Dotfiles installation completed successfully!"
    log_info "Please restart your editors to apply the new settings."
}

# スクリプトの実行
main "$@"
