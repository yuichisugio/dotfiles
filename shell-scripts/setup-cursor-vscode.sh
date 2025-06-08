#!/bin/bash

# unified-dotfiles-setup.sh - VS Code & Cursor 統合設定管理スクリプト
# このスクリプトは、VS CodeとCursorの設定を統合的に管理し、
# 拡張機能のインストールまで自動化します

set -e  # エラーが発生した場合にスクリプトを停止

# =============================================================================
# カラー出力とログ関数の定義
# =============================================================================

# ANSI カラーコードの定義（視認性向上のため）
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# ログ出力関数群
# これらの関数は、スクリプトの実行状況をユーザーに分かりやすく伝えるためのものです
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    echo -e "${PURPLE}[DEBUG]${NC} $1"
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# =============================================================================
# システム環境検出関数
# =============================================================================

# OSタイプを検出する関数
# この関数は、異なるOS間での設定ディレクトリパスの違いを吸収します
detect_os() {
    case "$OSTYPE" in
        darwin*)    echo "macos" ;;      # macOS
        linux*)     echo "linux" ;;     # Linux系OS
        msys*|win*) echo "windows" ;;   # Windows (Git Bash/MSYS2)
        cygwin*)    echo "windows" ;;   # Windows (Cygwin)
        *)          echo "unknown" ;;   # 未対応OS
    esac
}

# アプリケーションがインストールされているかチェックする関数
# 引数: アプリケーション名（例: "code", "cursor"）
# 戻り値: 0=存在, 1=存在しない
check_application_exists() {
    local app_name="$1"
    
    if command -v "$app_name" &> /dev/null; then
        log_success "$app_name が見つかりました"
        return 0
    else
        log_warning "$app_name がインストールされていません。スキップします。"
        return 1
    fi
}

# =============================================================================
# 設定ディレクトリパス取得関数
# =============================================================================

# VS Codeの設定ディレクトリパスを取得
# OSごとに異なる設定ディレクトリのパスを返します
get_vscode_config_path() {
    local os=$(detect_os)
    
    case $os in
        "macos")
            echo "$HOME/Library/Application Support/Code/User"
            ;;
        "linux")
            echo "$HOME/.config/Code/User"
            ;;
        "windows")
            echo "$APPDATA/Code/User"
            ;;
        *)
            log_error "サポートされていないOS: $os"
            return 1
            ;;
    esac
}

# Cursorの設定ディレクトリパスを取得
# Cursorは比較的新しいエディタのため、設定パスの確認が重要です
get_cursor_config_path() {
    local os=$(detect_os)
    
    case $os in
        "macos")
            echo "$HOME/Library/Application Support/Cursor/User"
            ;;
        "linux")
            echo "$HOME/.config/Cursor/User"
            ;;
        "windows")
            echo "$APPDATA/Cursor/User"
            ;;
        *)
            log_error "サポートされていないOS: $os"
            return 1
            ;;
    esac
}

# dotfilesリポジトリのパス取得
# スクリプトの実行場所から相対的にdotfilesディレクトリを特定します
get_dotfiles_path() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # スクリプトがscripts/ディレクトリ内にある場合の処理
    if [[ "$(basename "$script_dir")" == "scripts" ]]; then
        echo "$(dirname "$script_dir")"
    else
        echo "$script_dir"
    fi
}

# =============================================================================
# バックアップ関数群
# =============================================================================

# タイムスタンプ付きバックアップディレクトリ名を生成
generate_backup_timestamp() {
    date +"%Y%m%d_%H%M%S"
}

# 設定ファイルの包括的バックアップを作成
# この関数は、既存の設定を安全に保管してから新しい設定を適用します
create_comprehensive_backup() {
    local app_name="$1"
    local config_dir="$2"
    local timestamp=$(generate_backup_timestamp)
    local backup_dir="$HOME/.${app_name}-backup-$timestamp"
    
    log_step "$app_name の設定をバックアップ中..."
    
    # 設定ディレクトリが存在する場合のみバックアップを実行
    if [ -d "$config_dir" ]; then
        mkdir -p "$backup_dir"
        
        # 設定ファイルをバックアップディレクトリにコピー
        cp -r "$config_dir" "$backup_dir/"
        log_success "設定ファイルをバックアップしました: $backup_dir"
        
        # 拡張機能リストもバックアップ（該当アプリが存在する場合）
        if command -v "$app_name" &> /dev/null; then
            local extensions_backup="$backup_dir/extensions-$timestamp.txt"
            "$app_name" --list-extensions > "$extensions_backup" 2>/dev/null || true
            log_success "拡張機能リストをバックアップしました: $extensions_backup"
        fi
    else
        log_info "$app_name の既存設定が見つかりません。新規セットアップを行います。"
    fi
}

# =============================================================================
# 設定ファイル管理関数群
# =============================================================================

# シンボリックリンクを安全に作成する関数
# 既存ファイルとの競合を避けながら、設定ファイルをリンクします
create_safe_symlink() {
    local source_file="$1"
    local target_file="$2"
    local file_description="$3"
    
    # ソースファイルの存在確認
    if [ ! -f "$source_file" ]; then
        log_warning "$file_description のソースファイルが見つかりません: $source_file"
        return 1
    fi
    
    # ターゲットディレクトリの作成（必要に応じて）
    local target_dir=$(dirname "$target_file")
    mkdir -p "$target_dir"
    
    # 既存ファイルやシンボリックリンクを削除
    if [ -e "$target_file" ] || [ -L "$target_file" ]; then
        rm "$target_file"
    fi
    
    # シンボリックリンクを作成
    ln -s "$source_file" "$target_file"
    log_success "$file_description のシンボリックリンクを作成しました"
}

# スニペットディレクトリの同期
# カスタムスニペットファイルを効率的に管理します
sync_snippets_directory() {
    local app_name="$1"
    local config_dir="$2"
    local dotfiles_dir="$3"
    
    local snippets_source="$dotfiles_dir/$app_name/snippets"
    local snippets_target="$config_dir/snippets"
    
    if [ -d "$snippets_source" ]; then
        log_step "$app_name のスニペットを同期中..."
        
        # スニペットディレクトリを作成
        mkdir -p "$snippets_target"
        
        # 各スニペットファイルをリンク
        for snippet_file in "$snippets_source"/*.json; do
            if [ -f "$snippet_file" ]; then
                local filename=$(basename "$snippet_file")
                local target_path="$snippets_target/$filename"
                
                create_safe_symlink "$snippet_file" "$target_path" "スニペット($filename)"
            fi
        done
    else
        log_info "$app_name 用のスニペットディレクトリが見つかりません。スキップします。"
    fi
}

# =============================================================================
# 拡張機能管理関数群
# =============================================================================

# 拡張機能リストファイルから拡張機能をインストール
# extensions.txtファイルに記載された拡張機能を一括インストールします
install_extensions_from_file() {
    local app_name="$1"
    local extensions_file="$2"
    
    # 拡張機能リストファイルの存在確認
    if [ ! -f "$extensions_file" ]; then
        log_warning "$app_name 用の拡張機能リストが見つかりません: $extensions_file"
        log_info "以下のコマンドで現在の拡張機能リストを生成できます:"
        log_info "$app_name --list-extensions > $extensions_file"
        return 1
    fi
    
    log_step "$app_name の拡張機能をインストール中..."
    
    local installed_count=0
    local failed_count=0
    
    # 拡張機能を一行ずつ読み込んでインストール
    while IFS= read -r extension; do
        # 空行やコメント行（#で始まる行）をスキップ
        if [[ -n "$extension" && ! "$extension" =~ ^[[:space:]]*# ]]; then
            log_info "インストール中: $extension"
            
            # 拡張機能のインストールを試行
            if "$app_name" --install-extension "$extension" --force &> /dev/null; then
                log_success "インストール完了: $extension"
                ((installed_count++))
            else
                log_warning "インストール失敗: $extension"
                ((failed_count++))
            fi
        fi
    done < "$extensions_file"
    
    # インストール結果のサマリーを表示
    log_success "$app_name: $installed_count 個の拡張機能をインストールしました"
    if [ "$failed_count" -gt 0 ]; then
        log_warning "$app_name: $failed_count 個の拡張機能のインストールに失敗しました"
    fi
}

# 現在インストールされている拡張機能リストを生成
# バックアップや設定の同期に使用します
generate_current_extensions_list() {
    local app_name="$1"
    local output_file="$2"
    
    if command -v "$app_name" &> /dev/null; then
        log_step "$app_name の現在の拡張機能リストを生成中..."
        
        "$app_name" --list-extensions > "$output_file"
        local extension_count=$(wc -l < "$output_file")
        
        log_success "$extension_count 個の拡張機能をリストアップしました: $output_file"
        
        # 最初の5個の拡張機能を表示
        log_info "インストール済み拡張機能（抜粋）:"
        head -5 "$output_file" | while read -r extension; do
            echo "  - $extension"
        done
        
        if [ "$extension_count" -gt 5 ]; then
            log_info "  ... 他 $((extension_count - 5)) 個"
        fi
    else
        log_error "$app_name が見つからないため、拡張機能リストを生成できません"
        return 1
    fi
}

# =============================================================================
# アプリケーション別設定関数群
# =============================================================================

# VS Code設定の包括的セットアップ
# 設定ファイル、スニペット、拡張機能を一括で管理します
setup_vscode() {
    local app_name="code"
    
    # VS Codeのインストール確認
    if ! check_application_exists "$app_name"; then
        return 0
    fi
    
    log_step "=== VS Code 設定セットアップ開始 ==="
    
    local config_dir=$(get_vscode_config_path)
    local dotfiles_dir=$(get_dotfiles_path)
    local vscode_dotfiles="$dotfiles_dir/vscode"
    
    # dotfiles内のVS Code設定ディレクトリ確認
    if [ ! -d "$vscode_dotfiles" ]; then
        log_warning "VS Code用dotfilesディレクトリが見つかりません: $vscode_dotfiles"
        log_info "ディレクトリを作成してサンプル設定を配置してください"
        return 1
    fi
    
    # 既存設定のバックアップ
    create_comprehensive_backup "$app_name" "$config_dir"
    
    # 主要設定ファイルのシンボリックリンク作成
    local settings_files=("settings.json" "keybindings.json")
    for file in "${settings_files[@]}"; do
        create_safe_symlink \
            "$vscode_dotfiles/$file" \
            "$config_dir/$file" \
            "VS Code $file"
    done
    
    # スニペットの同期
    sync_snippets_directory "$app_name" "$config_dir" "$dotfiles_dir"
    
    # 拡張機能のインストール
    local extensions_file="$vscode_dotfiles/extensions.txt"
    install_extensions_from_file "$app_name" "$extensions_file"
    
    log_success "=== VS Code 設定セットアップ完了 ==="
}

# Cursor設定の包括的セットアップ
# Cursorは VS Code と互換性がありながら独自の設定も持ちます
setup_cursor() {
    local app_name="cursor"
    
    # Cursorのインストール確認
    if ! check_application_exists "$app_name"; then
        return 0
    fi
    
    log_step "=== Cursor 設定セットアップ開始 ==="
    
    local config_dir=$(get_cursor_config_path)
    local dotfiles_dir=$(get_dotfiles_path)
    local cursor_dotfiles="$dotfiles_dir/cursor"
    
    # dotfiles内のCursor設定ディレクトリ確認
    if [ ! -d "$cursor_dotfiles" ]; then
        log_warning "Cursor用dotfilesディレクトリが見つかりません: $cursor_dotfiles"
        
        # VS Code設定からのフォールバック処理
        local vscode_dotfiles="$dotfiles_dir/vscode"
        if [ -d "$vscode_dotfiles" ]; then
            log_info "VS Code設定をCursorにも適用します"
            cursor_dotfiles="$vscode_dotfiles"
        else
            log_info "ディレクトリを作成してサンプル設定を配置してください"
            return 1
        fi
    fi
    
    # 既存設定のバックアップ
    create_comprehensive_backup "$app_name" "$config_dir"
    
    # 主要設定ファイルのシンボリックリンク作成
    local settings_files=("settings.json" "keybindings.json")
    for file in "${settings_files[@]}"; do
        create_safe_symlink \
            "$cursor_dotfiles/$file" \
            "$config_dir/$file" \
            "Cursor $file"
    done
    
    # スニペットの同期
    sync_snippets_directory "cursor" "$config_dir" "$dotfiles_dir"
    
    # 拡張機能のインストール（CursorはVS Code互換）
    local extensions_file="$cursor_dotfiles/extensions.txt"
    install_extensions_from_file "$app_name" "$extensions_file"
    
    log_success "=== Cursor 設定セットアップ完了 ==="
}

# Git設定のセットアップ
# 開発環境において重要なGit設定も統合的に管理します
setup_git() {
    log_step "=== Git 設定セットアップ開始 ==="
    
    local dotfiles_dir=$(get_dotfiles_path)
    local git_dotfiles="$dotfiles_dir/git"
    
    # Git設定ディレクトリの確認
    if [ ! -d "$git_dotfiles" ]; then
        log_warning "Git用dotfilesディレクトリが見つかりません: $git_dotfiles"
        log_info "Gitの設定セットアップをスキップします"
        return 0
    fi
    
    # 既存のGit設定をバックアップ
    local timestamp=$(generate_backup_timestamp)
    if [ -f "$HOME/.gitconfig" ]; then
        log_info "既存のGit設定をバックアップ中..."
        cp "$HOME/.gitconfig" "$HOME/.gitconfig.backup.$timestamp"
    fi
    
    # Git設定ファイルのシンボリックリンク作成
    local git_files=(".gitconfig" ".gitignore_global")
    for file in "${git_files[@]}"; do
        if [ -f "$git_dotfiles/$file" ]; then
            create_safe_symlink \
                "$git_dotfiles/$file" \
                "$HOME/$file" \
                "Git $file"
        fi
    done
    
    log_success "=== Git 設定セットアップ完了 ==="
}

# =============================================================================
# ユーティリティ関数群
# =============================================================================

# 設定の差分確認（Git使用）
show_configuration_diff() {
    local dotfiles_dir=$(get_dotfiles_path)
    
    log_step "設定ファイルの変更差分を確認中..."
    
    cd "$dotfiles_dir"
    
    if [ -d ".git" ]; then
        if ! git diff --quiet HEAD 2>/dev/null; then
            log_info "dotfiles設定の変更点:"
            git diff HEAD
        else
            log_info "dotfiles設定に変更はありません"
        fi
    else
        log_info "Gitリポジトリではないため、差分を表示できません"
    fi
}

# 現在の設定をdotfilesにバックアップ
backup_current_settings() {
    local dotfiles_dir=$(get_dotfiles_path)
    
    log_step "=== 現在の設定をdotfilesにバックアップ中 ==="
    
    # VS Code設定のバックアップ
    if check_application_exists "code"; then
        local vscode_config=$(get_vscode_config_path)
        local vscode_dotfiles="$dotfiles_dir/vscode"
        
        mkdir -p "$vscode_dotfiles/snippets"
        
        # 設定ファイルのコピー
        cp "$vscode_config/settings.json" "$vscode_dotfiles/" 2>/dev/null || true
        cp "$vscode_config/keybindings.json" "$vscode_dotfiles/" 2>/dev/null || true
        
        # 拡張機能リストの生成
        generate_current_extensions_list "code" "$vscode_dotfiles/extensions.txt"
    fi
    
    # Cursor設定のバックアップ
    if check_application_exists "cursor"; then
        local cursor_config=$(get_cursor_config_path)
        local cursor_dotfiles="$dotfiles_dir/cursor"
        
        mkdir -p "$cursor_dotfiles/snippets"
        
        # 設定ファイルのコピー
        cp "$cursor_config/settings.json" "$cursor_dotfiles/" 2>/dev/null || true
        cp "$cursor_config/keybindings.json" "$cursor_dotfiles/" 2>/dev/null || true
        
        # 拡張機能リストの生成
        generate_current_extensions_list "cursor" "$cursor_dotfiles/extensions.txt"
    fi
    
    log_success "=== 現在の設定のバックアップ完了 ==="
}

# 使用方法の表示
show_usage() {
    echo "使用方法: $0 [オプション]"
    echo ""
    echo "このスクリプトは VS Code と Cursor の設定を統合的に管理します"
    echo ""
    echo "オプション:"
    echo "  --backup        現在の設定をdotfilesにバックアップ"
    echo "  --diff          設定の変更差分を表示"
    echo "  --vscode-only   VS Code設定のみを適用"
    echo "  --cursor-only   Cursor設定のみを適用"
    echo "  --help          このヘルプを表示"
    echo ""
    echo "例:"
    echo "  $0                    # 全体セットアップを実行"
    echo "  $0 --backup           # 現在の設定をバックアップ"
    echo "  $0 --vscode-only      # VS Code設定のみを適用"
    echo "  $0 --diff             # 設定の変更差分を表示"
}

# =============================================================================
# メイン実行関数
# =============================================================================

# メイン処理の実行
# コマンドライン引数に応じて適切な処理を実行します
main() {
    # スクリプト開始のアナウンス
    echo "========================================================"
    echo "  VS Code & Cursor 統合dotfiles管理スクリプト"
    echo "========================================================"
    
    local dotfiles_dir=$(get_dotfiles_path)
    log_info "dotfilesディレクトリ: $dotfiles_dir"
    log_info "検出OS: $(detect_os)"
    echo ""
    
    # コマンドライン引数の処理
    case "${1:-}" in
        --backup)
            backup_current_settings
            return 0
            ;;
        --diff)
            show_configuration_diff
            return 0
            ;;
        --vscode-only)
            setup_vscode
            return 0
            ;;
        --cursor-only)
            setup_cursor
            return 0
            ;;
        --help)
            show_usage
            return 0
            ;;
        "")
            # 引数なしの場合は全体セットアップを実行
            ;;
        *)
            log_error "不明なオプション: $1"
            show_usage
            exit 1
            ;;
    esac
    
    # 統合セットアップの実行
    log_step "統合設定セットアップを開始します..."
    
    # 各アプリケーションの設定を順次実行
    setup_vscode
    echo ""
    setup_cursor
    echo ""
    setup_git
    
    # セットアップ完了のアナウンス
    echo ""
    echo "========================================================"
    log_success "統合dotfiles設定が完了しました！"
    echo "========================================================"
    
    # 再起動の推奨
    log_info "変更を適用するために、以下のアプリケーションを再起動してください:"
    check_application_exists "code" && echo "  - VS Code"
    check_application_exists "cursor" && echo "  - Cursor"
    
    echo ""
    log_info "設定の詳細確認: $0 --diff"
    log_info "設定のバックアップ: $0 --backup"
}

# =============================================================================
# エラーハンドリングとスクリプト実行
# =============================================================================

# エラーハンドリングの設定
# スクリプト実行中にエラーが発生した場合の処理を定義
trap 'log_error "スクリプト実行中にエラーが発生しました (行番号: $LINENO)"; exit 1' ERR

# メイン関数の実行
# このスクリプトが直接実行された場合のみmain関数を呼び出します
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
