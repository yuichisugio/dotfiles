#!/bin/bash
# dotfiles管理用の完全なインストールスクリプト（WSL対応版）
set -e

# カラー出力用の定数定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ログ出力関数
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_debug() { echo -e "${BLUE}[DEBUG]${NC} $1"; }

# 環境検出関数（WSL対応）
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

# WSL環境での追加情報取得
if [[ "$ENVIRONMENT" == "wsl" ]]; then
    # WSLのバージョンを確認
    WSL_VERSION=$(wsl.exe -l -v 2>/dev/null | grep -E "^\s*\*" | awk '{print $4}' || echo "unknown")
    # Windowsのユーザー名を取得
    WINDOWS_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r' || whoami)
    WINDOWS_HOME="/mnt/c/Users/$WINDOWS_USER"
    
    log_info "WSL環境を検出しました"
    log_info "WSLバージョン: $WSL_VERSION"
    log_info "Windowsユーザー: $WINDOWS_USER"
fi

# スクリプト自身のディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# shell-scriptsディレクトリの親ディレクトリ（dotfilesのルート）を取得
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

log_debug "Script directory: $SCRIPT_DIR"
log_debug "Dotfiles directory: $DOTFILES_DIR"
log_debug "Environment: $ENVIRONMENT"

# バックアップディレクトリの作成
create_backup_dir() {
    local backup_dir="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    echo "$backup_dir"
}

# ファイルまたはディレクトリの存在確認
check_source_exists() {
    local source_path="$1"
    local file_type="$2"
    
    if [ ! -e "$source_path" ]; then
        log_error "$file_type not found at: $source_path"
        return 1
    fi
    log_debug "$file_type exists at: $source_path"
    return 0
}

# 既存ファイルの安全なバックアップ関数
backup_if_exists() {
    local file_path="$1"
    local backup_dir="$2"
    
    if [ -e "$file_path" ] || [ -L "$file_path" ]; then
        local file_name=$(basename "$file_path")
        log_warn "Backing up existing file/link: $file_path"
        # シンボリックリンクの場合も含めて完全に削除
        if [ -L "$file_path" ]; then
            rm -f "$file_path"
        else
            cp -r "$file_path" "$backup_dir/$file_name"
            rm -rf "$file_path"
        fi
    fi
}

# 安全なシンボリックリンク作成関数
create_symlink() {
    local source="$1"
    local target="$2"
    local description="$3"
    
    # ソースファイルの存在確認
    if [ ! -e "$source" ]; then
        log_error "Source not found: $source"
        return 1
    fi
    
    # 既存のリンクまたはファイルを削除
    if [ -L "$target" ] || [ -e "$target" ]; then
        rm -rf "$target"
    fi
    
    # シンボリックリンクを作成
    ln -sf "$source" "$target"
    
    # 作成されたリンクの確認
    if [ -L "$target" ] && [ -e "$target" ]; then
        log_info "✓ $description linked successfully"
        log_debug "  Link: $target -> $source"
        return 0
    else
        log_error "Failed to create symlink for $description"
        return 1
    fi
}

# 必要なパッケージのインストール（WSL/Linux用）
install_dependencies() {
    if [[ "$ENVIRONMENT" == "wsl" ]] || [[ "$ENVIRONMENT" == "linux" ]]; then
        log_info "Linux/WSL環境用の依存関係をチェックしています..."
        
        # 必要なパッケージのリスト
        local packages=("zsh" "git" "curl" "wget")
        local missing_packages=()
        
        # パッケージの存在確認
        for pkg in "${packages[@]}"; do
            if ! command -v "$pkg" &> /dev/null; then
                missing_packages+=("$pkg")
            fi
        done
        
        # 不足しているパッケージがある場合
        if [ ${#missing_packages[@]} -gt 0 ]; then
            log_warn "以下のパッケージがインストールされていません: ${missing_packages[*]}"
            echo -n "インストールしますか？ (y/N): "
            read -r response
            
            if [[ "$response" =~ ^[Yy]$ ]]; then
                log_info "パッケージをインストールします..."
                sudo apt update
                sudo apt install -y "${missing_packages[@]}"
                
                # zsh-syntax-highlightingとzsh-autosuggestionsもインストール
                if [[ " ${missing_packages[@]} " =~ " zsh " ]]; then
                    sudo apt install -y zsh-syntax-highlighting zsh-autosuggestions
                fi
            fi
        else
            log_info "✓ 必要なパッケージは全てインストール済みです"
        fi
    fi
}

# Zsh設定のセットアップ
setup_zsh() {
    log_info "Setting up Zsh configuration..."
    local backup_dir="$1"
    
    # .zshrcファイルの処理
    local zshrc_source="$DOTFILES_DIR/.zshrc"
    if check_source_exists "$zshrc_source" ".zshrc"; then
        backup_if_exists "$HOME/.zshrc" "$backup_dir"
        create_symlink "$zshrc_source" "$HOME/.zshrc" ".zshrc"
    fi
    
    # .zshディレクトリの処理
    local zsh_dir_source="$DOTFILES_DIR/.zsh"
    if check_source_exists "$zsh_dir_source" ".zsh directory"; then
        backup_if_exists "$HOME/.zsh" "$backup_dir"
        create_symlink "$zsh_dir_source" "$HOME/.zsh" ".zsh directory"
    fi
    
    # WSL環境での追加設定
    if [[ "$ENVIRONMENT" == "wsl" ]]; then
        log_info "WSL環境用の追加設定を行います..."
        
        # デフォルトシェルをzshに変更するか確認
        if [ "$SHELL" != "$(which zsh)" ]; then
            echo -n "デフォルトシェルをzshに変更しますか？ (y/N): "
            read -r response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                chsh -s $(which zsh)
                log_info "✓ デフォルトシェルをzshに変更しました"
            fi
        fi
    fi
}

# Claude AI設定のセットアップ
setup_claude() {
    log_info "Setting up Claude AI configuration..."
    local backup_dir="$1"
    
    # .claudeディレクトリの処理
    local claude_source="$DOTFILES_DIR/.claude"
    if check_source_exists "$claude_source" ".claude directory"; then
        backup_if_exists "$HOME/.claude" "$backup_dir"
        create_symlink "$claude_source" "$HOME/.claude" ".claude directory"
        
        # 設定ファイルの存在確認（リンク作成後）
        if [ -f "$HOME/.claude/CLAUDE.md" ] && [ -f "$HOME/.claude/settings.json" ]; then
            log_info "✓ CLAUDE.md and settings.json are accessible"
        else
            log_warn "Some Claude configuration files may be missing"
            [ ! -f "$HOME/.claude/CLAUDE.md" ] && log_warn "  - CLAUDE.md not found"
            [ ! -f "$HOME/.claude/settings.json" ] && log_warn "  - settings.json not found"
        fi
    fi
}

# Git設定のセットアップ（WSL対応）
setup_git() {
    log_info "Setting up Git configuration..."
    local backup_dir="$1"
    
    # .gitconfigファイルの処理
    local gitconfig_source="$DOTFILES_DIR/.gitconfig"
    if check_source_exists "$gitconfig_source" ".gitconfig"; then
        backup_if_exists "$HOME/.gitconfig" "$backup_dir"
        create_symlink "$gitconfig_source" "$HOME/.gitconfig" ".gitconfig"
    fi
    
    # .gitignore_globalファイルの処理
    local gitignore_source="$DOTFILES_DIR/.gitignore_global"
    if check_source_exists "$gitignore_source" ".gitignore_global"; then
        backup_if_exists "$HOME/.gitignore_global" "$backup_dir"
        create_symlink "$gitignore_source" "$HOME/.gitignore_global" ".gitignore_global"
    fi
    
    # WSL環境でのGit設定
    if [[ "$ENVIRONMENT" == "wsl" ]]; then
        log_info "WSL環境用のGit設定を行います..."
        
        # Gitの改行コード設定（Windows/Linux間の相互運用性のため）
        git config --global core.autocrlf input
        
        # WSLでのファイルモード設定（Windows側との互換性のため）
        git config --global core.filemode false
        
        log_info "✓ WSL用のGit設定を適用しました"
    fi
}

# WSL環境でのWindows側との統合設定
setup_wsl_integration() {
    if [[ "$ENVIRONMENT" != "wsl" ]]; then
        return 0
    fi
    
    log_info "WSL統合設定を行います..."
    
    # Windows側のVS Code/Cursor設定ディレクトリへのシンボリックリンク作成
    if [[ -d "$WINDOWS_HOME" ]]; then
        # VS Code設定の共有（オプション）
        echo -n "Windows側のVS Code設定を共有しますか？ (y/N): "
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            local vscode_win_path="$WINDOWS_HOME/AppData/Roaming/Code/User"
            local vscode_wsl_path="$HOME/.config/Code/User"
            
            if [[ -d "$vscode_win_path" ]]; then
                mkdir -p "$(dirname "$vscode_wsl_path")"
                ln -sf "$vscode_win_path" "$vscode_wsl_path"
                log_info "✓ VS Code設定をWindows側と共有しました"
            else
                log_warn "Windows側のVS Code設定が見つかりません"
            fi
        fi
    fi
    
    # WSL設定ファイルの作成
    create_wsl_conf
}

# WSL設定ファイル（/etc/wsl.conf）の作成
create_wsl_conf() {
    log_info "WSL設定ファイル（wsl.conf）を確認しています..."
    
    if [ ! -f /etc/wsl.conf ]; then
        echo -n "/etc/wsl.confを作成しますか？ (y/N): "
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            sudo tee /etc/wsl.conf > /dev/null <<EOF
[automount]
enabled = true
options = "metadata,umask=22,fmask=11"
mountFsTab = true

[network]
generateHosts = true
generateResolvConf = true

[interop]
enabled = true
appendWindowsPath = true
EOF
            log_info "✓ /etc/wsl.conf を作成しました"
            log_warn "設定を反映するにはWSLの再起動が必要です"
        fi
    else
        log_info "✓ /etc/wsl.conf は既に存在します"
    fi
}

# シンボリックリンクの状態を確認する関数
verify_symlinks() {
    log_info "Verifying created symlinks..."
    local has_errors=0
    
    # チェックするシンボリックリンクのリスト
    local symlinks=(
        "$HOME/.zshrc"
        "$HOME/.zsh"
        "$HOME/.claude"
        "$HOME/.gitconfig"
        "$HOME/.gitignore_global"
    )
    
    for link in "${symlinks[@]}"; do
        if [ -L "$link" ]; then
            if [ -e "$link" ]; then
                log_info "✓ $link is valid"
            else
                log_error "✗ $link is broken (target not found)"
                has_errors=1
            fi
        elif [ -e "$link" ]; then
            log_warn "! $link exists but is not a symlink"
        fi
    done
    
    return $has_errors
}

# メイン実行関数
main() {
    log_info "Starting comprehensive dotfiles installation..."
    log_info "Detected environment: $ENVIRONMENT"
    log_info "Dotfiles root directory: $DOTFILES_DIR"
    
    # dotfilesディレクトリの存在確認
    if [ ! -d "$DOTFILES_DIR" ]; then
        log_error "Dotfiles directory not found: $DOTFILES_DIR"
        exit 1
    fi
    
    # 依存関係のインストール（WSL/Linux環境のみ）
    install_dependencies
    
    # バックアップディレクトリの作成
    local backup_dir=$(create_backup_dir)
    log_info "Backup directory created: $backup_dir"
    
    # 各設定のセットアップを実行
    setup_zsh "$backup_dir"
    setup_claude "$backup_dir"
    setup_git "$backup_dir"
    
    # WSL環境での追加設定
    if [[ "$ENVIRONMENT" == "wsl" ]]; then
        setup_wsl_integration
    fi
    
    # シンボリックリンクの検証
    echo ""
    if verify_symlinks; then
        log_info "All symlinks are valid!"
    else
        log_warn "Some symlinks may have issues. Please check the errors above."
    fi
    
    echo ""
    log_info "Dotfiles installation completed!"
    log_info "Original files backed up to: $backup_dir"
    
    # 環境別の追加メッセージ
    if [[ "$ENVIRONMENT" == "wsl" ]]; then
        log_info ""
        log_info "WSL環境での次のステップ:"
        log_info "1. ターミナルを再起動してzsh設定を反映"
        log_info "2. Windows側のVS Code/Cursorで 'Remote - WSL' 拡張機能をインストール"
        log_info "3. VS Code/Cursorから 'WSL: Connect to WSL' コマンドを実行"
    else
        log_info "Please restart your shell and editors to apply the new settings."
    fi
    
    # デバッグ情報の表示（必要に応じてコメントアウト）
    if [ "${DEBUG:-0}" = "1" ]; then
        echo ""
        log_debug "Created symlinks:"
        ls -la "$HOME/.zshrc" "$HOME/.zsh" "$HOME/.claude" "$HOME/.gitconfig" "$HOME/.gitignore_global" 2>/dev/null || true
    fi
}

# スクリプトの実行
main "$@"
