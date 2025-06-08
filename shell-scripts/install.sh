#!/bin/bash
# dotfiles管理用の完全なインストールスクリプト
set -e

# カラー出力用の定数定義（既存のまま）
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ログ出力関数（既存のまま）
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# バックアップディレクトリの作成
create_backup_dir() {
    local backup_dir="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    echo "$backup_dir"
}

# 既存ファイルの安全なバックアップ関数
backup_if_exists() {
    local file_path="$1"
    local backup_dir="$2"
    
    if [ -e "$file_path" ]; then
        local file_name=$(basename "$file_path")
        log_warn "Backing up existing file: $file_path"
        cp -r "$file_path" "$backup_dir/$file_name"
        rm -rf "$file_path"
    fi
}

# Zsh設定のセットアップ
setup_zsh() {
    log_info "Setting up Zsh configuration..."
    local backup_dir="$1"
    
    # .zshrcファイルの処理
    backup_if_exists "$HOME/.zshrc" "$backup_dir"
    ln -sf "$PWD/.zshrc" "$HOME/.zshrc"
    
    # .zshディレクトリの処理
    backup_if_exists "$HOME/.zsh" "$backup_dir"
    ln -sf "$PWD/.zsh" "$HOME/.zsh"
    
    log_info "Zsh configuration linked successfully"
}

# Claude AI設定のセットアップ
setup_claude() {
    log_info "Setting up Claude AI configuration..."
    local backup_dir="$1"
    
    # .claudeディレクトリの処理
    backup_if_exists "$HOME/.claude" "$backup_dir"
    ln -sf "$PWD/.claude" "$HOME/.claude"
    
    # 設定ファイルの存在確認
    if [ -f "$HOME/.claude/CLAUDE.md" ] && [ -f "$HOME/.claude/settings.json" ]; then
        log_info "Claude configuration linked successfully"
        log_info "✓ CLAUDE.md and settings.json are accessible"
    else
        log_warn "Claude configuration files may be missing"
    fi
}

# Git設定のセットアップ（修正版）
setup_git() {
    log_info "Setting up Git configuration..."
    local backup_dir="$1"
    
    # .gitconfigファイルの処理
    backup_if_exists "$HOME/.gitconfig" "$backup_dir"
    ln -sf "$PWD/.gitconfig" "$HOME/.gitconfig"
    
    # .gitignore_globalファイルの処理
    backup_if_exists "$HOME/.gitignore_global" "$backup_dir"
    ln -sf "$PWD/.gitignore_global" "$HOME/.gitignore_global"
    
    log_info "Git configuration linked successfully"
}


# メイン実行関数
main() {
    log_info "Starting comprehensive dotfiles installation..."
    
    # バックアップディレクトリの作成
    local backup_dir=$(create_backup_dir)
    log_info "Backup directory created: $backup_dir"
    
    # 各設定のセットアップを実行
    setup_zsh "$backup_dir"
    setup_claude "$backup_dir"
    setup_git "$backup_dir"
    setup_vscode "$(detect_os)" "$backup_dir"
    setup_cursor "$(detect_os)" "$backup_dir"
    
    log_info "Dotfiles installation completed successfully!"
    log_info "All original files have been backed up to: $backup_dir"
    log_info "Please restart your shell and editors to apply the new settings."
}

# スクリプトの実行
main "$@"
