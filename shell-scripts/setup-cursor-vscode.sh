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

# dotfilesリポジトリのパス取得（修正版）
# より柔軟にdotfilesのルートディレクトリを検出します
get_dotfiles_path() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local current_dir="$script_dir"
    
    # dotfilesのルートディレクトリを探索
    # .gitconfigや.zshrcなどの典型的なdotfilesが存在するディレクトリを探す
    while [ "$current_dir" != "/" ]; do
        # dotfilesの典型的なファイルやディレクトリが存在するかチェック
        if [ -f "$current_dir/.gitconfig" ] || [ -f "$current_dir/.zshrc" ] || \
           [ -d "$current_dir/vscode" ] || [ -d "$current_dir/cursor" ]; then
            echo "$current_dir"
            return 0
        fi
        
        # 親ディレクトリに移動
        current_dir="$(dirname "$current_dir")"
    done
    
    # 見つからない場合は、スクリプトディレクトリの親ディレクトリを返す
    # （shell-scriptsディレクトリから実行されている場合を想定）
    local basename_dir="$(basename "$script_dir")"
    if [[ "$basename_dir" == "shell-scripts" || "$basename_dir" == "scripts" ]]; then
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
# 拡張機能管理関数群（改良版）
# =============================================================================

# 現在インストールされている拡張機能を保存する関数
# installed-extensions.txt に現在の拡張機能リストを保存します
save_installed_extensions() {
    local app_name="$1"
    local output_file="$2"
    
    if command -v "$app_name" &> /dev/null; then
        log_step "$app_name の現在の拡張機能リストを保存中..."
        
        # ディレクトリが存在しない場合は作成
        mkdir -p "$(dirname "$output_file")"
        
        # 拡張機能リストを保存
        "$app_name" --list-extensions > "$output_file"
        local extension_count=$(wc -l < "$output_file")
        
        log_success "$extension_count 個の拡張機能を保存しました: $output_file"
        
        # 最初の5個の拡張機能を表示
        if [ "$extension_count" -gt 0 ]; then
            log_info "インストール済み拡張機能（抜粋）:"
            head -5 "$output_file" | while read -r extension; do
                echo "  - $extension"
            done
            
            if [ "$extension_count" -gt 5 ]; then
                log_info "  ... 他 $((extension_count - 5)) 個"
            fi
        fi
    else
        log_error "$app_name が見つからないため、拡張機能リストを保存できません"
        return 1
    fi
}

# 推奨拡張機能とインストール済み拡張機能の差分を計算する関数
# recommended-extensions.txt と installed-extensions.txt の差分を計算します
calculate_extensions_diff() {
    local recommended_file="$1"
    local installed_file="$2"
    local diff_file="$3"
    
    # 推奨拡張機能ファイルが存在しない場合
    if [ ! -f "$recommended_file" ]; then
        log_warning "推奨拡張機能リストが見つかりません: $recommended_file"
        return 1
    fi
    
    # インストール済みファイルが存在しない場合は空のファイルとして扱う
    if [ ! -f "$installed_file" ]; then
        log_info "インストール済み拡張機能リストが存在しません。全ての推奨拡張機能をインストール対象とします。"
        # 推奨拡張機能をそのまま差分ファイルにコピー（コメント行を除く）
        grep -v '^[[:space:]]*#' "$recommended_file" | grep -v '^[[:space:]]*$' > "$diff_file"
    else
        # 差分を計算（推奨拡張機能のうち、まだインストールされていないもの）
        # コメント行と空行を除外して処理
        grep -v '^[[:space:]]*#' "$recommended_file" | grep -v '^[[:space:]]*$' | \
        while read -r extension; do
            if ! grep -q "^${extension}$" "$installed_file"; then
                echo "$extension"
            fi
        done > "$diff_file"
    fi
    
    # 差分の数を返す
    if [ -f "$diff_file" ] && [ -s "$diff_file" ]; then
        wc -l < "$diff_file"
    else
        echo "0"
    fi
}

# 差分拡張機能のみをインストールする関数
# 推奨拡張機能のうち、まだインストールされていないもののみをインストールします
install_extension_diff() {
    local app_name="$1"
    local recommended_file="$2"
    local installed_file="$3"
    
    # 一時ファイルで差分を管理
    local temp_diff="/tmp/${app_name}_extensions_diff.txt"
    
    # 現在インストールされている拡張機能を保存
    save_installed_extensions "$app_name" "$installed_file"
    
    # 差分を計算
    local diff_count=$(calculate_extensions_diff "$recommended_file" "$installed_file" "$temp_diff")
    
    if [ "$diff_count" -eq 0 ]; then
        log_success "全ての推奨拡張機能が既にインストールされています"
        rm -f "$temp_diff"
        return 0
    fi
    
    log_step "$diff_count 個の新しい拡張機能をインストールします"
    
    # 差分拡張機能の一覧を表示
    log_info "インストール予定の拡張機能:"
    cat "$temp_diff" | while read -r extension; do
        echo "  - $extension"
    done
    
    echo ""
    
    # 差分拡張機能をインストール
    local installed_count=0
    local failed_count=0
    
    while IFS= read -r extension; do
        if [[ -n "$extension" ]]; then
            log_info "インストール中: $extension"
            
            if "$app_name" --install-extension "$extension" --force &> /dev/null; then
                log_success "インストール完了: $extension"
                ((installed_count++))
            else
                log_warning "インストール失敗: $extension"
                ((failed_count++))
            fi
        fi
    done < "$temp_diff"
    
    # インストール後、再度インストール済みリストを更新
    save_installed_extensions "$app_name" "$installed_file"
    
    # インストール結果のサマリーを表示
    log_success "$app_name: $installed_count 個の拡張機能を新規インストールしました"
    if [ "$failed_count" -gt 0 ]; then
        log_warning "$app_name: $failed_count 個の拡張機能のインストールに失敗しました"
    fi
    
    # 一時ファイルを削除
    rm -f "$temp_diff"
}

# recommended-extensions.txt ファイルの確認と初期作成を行う関数
# 推奨拡張機能リストが存在しない場合、サンプルファイルを作成します
ensure_recommended_extensions_file() {
    local app_name="$1"
    local recommended_file="$2"
    local installed_file="$3"
    
    # recommended-extensions.txt が既に存在する場合は何もしない
    if [ -f "$recommended_file" ]; then
        log_info "$app_name 用の推奨拡張機能リストが見つかりました: $recommended_file"
        return 0
    fi
    
    log_warning "$app_name 用の推奨拡張機能リスト (recommended-extensions.txt) が見つかりません"
    
    # ディレクトリを作成
    mkdir -p "$(dirname "$recommended_file")"
    
    # アプリケーションが存在する場合、現在の拡張機能から推奨リストを生成するか確認
    if command -v "$app_name" &> /dev/null; then
        # 現在インストールされている拡張機能を確認
        local temp_file="/tmp/${app_name}_current_extensions.txt"
        "$app_name" --list-extensions > "$temp_file" 2>/dev/null || true
        
        if [ -s "$temp_file" ]; then
            local extension_count=$(wc -l < "$temp_file")
            log_info "現在 $extension_count 個の拡張機能がインストールされています"
            
            echo ""
            echo "現在インストールされている拡張機能から推奨リストを生成しますか？"
            echo -n "生成する場合は 'y' を入力してください (y/N): "
            read -r response
            
            if [[ "$response" =~ ^[Yy]$ ]]; then
                # 推奨拡張機能リストを生成
                echo "# $app_name 推奨拡張機能リスト" > "$recommended_file"
                echo "# このファイルに推奨する拡張機能IDを1行ずつ記載してください" >> "$recommended_file"
                echo "# 例: ms-python.python" >> "$recommended_file"
                echo "# 生成日: $(date)" >> "$recommended_file"
                echo "" >> "$recommended_file"
                cat "$temp_file" >> "$recommended_file"
                
                log_success "推奨拡張機能リストを生成しました: $recommended_file"
                
                # インストール済みリストも保存
                cp "$temp_file" "$installed_file"
                log_success "インストール済み拡張機能リストも保存しました: $installed_file"
                
                rm -f "$temp_file"
                return 0
            fi
        fi
        
        rm -f "$temp_file"
    fi
    
    # サンプルのrecommended-extensions.txtを作成
    cat > "$recommended_file" << EOF
# $app_name 推奨拡張機能リスト
# このファイルに推奨する拡張機能IDを1行ずつ記載してください
# 例: ms-python.python
# 
# 以下は一般的な拡張機能の例です。必要に応じて編集してください。

# 基本的な開発ツール
# editorconfig.editorconfig
# streetsidesoftware.code-spell-checker

# Git関連
# eamodio.gitlens
# donjayamanne.githistory

# コード整形・リンター
# esbenp.prettier-vscode
# dbaeumer.vscode-eslint

# テーマ・アイコン
# pkief.material-icon-theme
# zhuangtongfa.material-theme
EOF

    log_info "サンプルの推奨拡張機能リストを作成しました: $recommended_file"
    log_info "必要な拡張機能IDを追加してから、再度このスクリプトを実行してください"
    
    return 1
}

# =============================================================================
# アプリケーション別設定関数群（修正版）
# =============================================================================

# VS Code設定の包括的セットアップ（修正版）
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
    
    # dotfilesディレクトリのデバッグ情報を表示
    log_debug "検出されたdotfilesディレクトリ: $dotfiles_dir"
    log_debug "VS Code設定を探しています: $vscode_dotfiles"
    
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
    
    # 拡張機能の処理（新しい差分管理方式）
    local recommended_file="$vscode_dotfiles/recommended-extensions.txt"
    local installed_file="$vscode_dotfiles/installed-extensions.txt"
    
    # recommended-extensions.txt ファイルの確認と必要に応じて作成
    ensure_recommended_extensions_file "$app_name" "$recommended_file" "$installed_file"
    
    # 推奨拡張機能の差分インストール
    if [ -f "$recommended_file" ] && [ -s "$recommended_file" ]; then
        install_extension_diff "$app_name" "$recommended_file" "$installed_file"
    else
        log_info "拡張機能のインストールをスキップしました"
    fi
    
    log_success "=== VS Code 設定セットアップ完了 ==="
}

# Cursor設定の包括的セットアップ（修正版）
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
    
    # dotfilesディレクトリのデバッグ情報を表示
    log_debug "検出されたdotfilesディレクトリ: $dotfiles_dir"
    log_debug "Cursor設定を探しています: $cursor_dotfiles"
    
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
    
    # 拡張機能の処理（新しい差分管理方式）
    local recommended_file="$cursor_dotfiles/recommended-extensions.txt"
    local installed_file="$cursor_dotfiles/installed-extensions.txt"
    
    # recommended-extensions.txt ファイルの確認と必要に応じて作成
    ensure_recommended_extensions_file "$app_name" "$recommended_file" "$installed_file"
    
    # 推奨拡張機能の差分インストール
    if [ -f "$recommended_file" ] && [ -s "$recommended_file" ]; then
        install_extension_diff "$app_name" "$recommended_file" "$installed_file"
    else
        log_info "拡張機能のインストールをスキップしました"
    fi
    
    log_success "=== Cursor 設定セットアップ完了 ==="
}

# Git設定のセットアップ
# 開発環境において重要なGit設定も統合的に管理します
setup_git() {
    log_step "=== Git 設定セットアップ開始 ==="
    
    local dotfiles_dir=$(get_dotfiles_path)
    local git_dotfiles="$dotfiles_dir"  # Gitファイルは通常ルートに配置
    
    # Git設定ファイルの存在確認
    if [ ! -f "$git_dotfiles/.gitconfig" ] && [ ! -f "$git_dotfiles/.gitignore_global" ]; then
        log_warning "Git設定ファイルが見つかりません"
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

# 現在の設定をdotfilesにバックアップ（修正版）
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
        
        # インストール済み拡張機能リストを保存
        save_installed_extensions "code" "$vscode_dotfiles/installed-extensions.txt"
    fi
    
    # Cursor設定のバックアップ
    if check_application_exists "cursor"; then
        local cursor_config=$(get_cursor_config_path)
        local cursor_dotfiles="$dotfiles_dir/cursor"
        
        mkdir -p "$cursor_dotfiles/snippets"
        
        # 設定ファイルのコピー
        cp "$cursor_config/settings.json" "$cursor_dotfiles/" 2>/dev/null || true
        cp "$cursor_config/keybindings.json" "$cursor_dotfiles/" 2>/dev/null || true
        
        # インストール済み拡張機能リストを保存
        save_installed_extensions "cursor" "$cursor_dotfiles/installed-extensions.txt"
    fi
    
    log_success "=== 現在の設定のバックアップ完了 ==="
}

# 拡張機能の管理状況を表示する関数
show_extensions_status() {
    local dotfiles_dir=$(get_dotfiles_path)
    
    log_step "=== 拡張機能の管理状況 ==="
    
    # VS Code の状況
    if check_application_exists "code"; then
        echo ""
        log_info "VS Code 拡張機能の状況:"
        
        local vscode_dotfiles="$dotfiles_dir/vscode"
        local recommended_file="$vscode_dotfiles/recommended-extensions.txt"
        local installed_file="$vscode_dotfiles/installed-extensions.txt"
        
        if [ -f "$recommended_file" ]; then
            local recommended_count=$(grep -v '^[[:space:]]*#' "$recommended_file" | grep -v '^[[:space:]]*$' | wc -l)
            echo "  推奨拡張機能数: $recommended_count"
        else
            echo "  推奨拡張機能リスト: 未作成"
        fi
        
        if [ -f "$installed_file" ]; then
            local installed_count=$(wc -l < "$installed_file")
            echo "  インストール済み拡張機能数: $installed_count"
        else
            echo "  インストール済みリスト: 未保存"
        fi
        
        # 差分を表示
        if [ -f "$recommended_file" ] && [ -f "$installed_file" ]; then
            local temp_diff="/tmp/vscode_status_diff.txt"
            local diff_count=$(calculate_extensions_diff "$recommended_file" "$installed_file" "$temp_diff")
            echo "  未インストールの推奨拡張機能数: $diff_count"
            
            if [ "$diff_count" -gt 0 ] && [ "$diff_count" -le 10 ]; then
                echo "  未インストールの拡張機能:"
                cat "$temp_diff" | while read -r extension; do
                    echo "    - $extension"
                done
            fi
            rm -f "$temp_diff"
        fi
    fi
    
    # Cursor の状況
    if check_application_exists "cursor"; then
        echo ""
        log_info "Cursor 拡張機能の状況:"
        
        local cursor_dotfiles="$dotfiles_dir/cursor"
        
        # VS Code設定を共有している場合の処理
        if [ ! -d "$cursor_dotfiles" ]; then
            cursor_dotfiles="$dotfiles_dir/vscode"
        fi
        
        local recommended_file="$cursor_dotfiles/recommended-extensions.txt"
        local installed_file="$cursor_dotfiles/installed-extensions.txt"
        
        if [ -f "$recommended_file" ]; then
            local recommended_count=$(grep -v '^[[:space:]]*#' "$recommended_file" | grep -v '^[[:space:]]*$' | wc -l)
            echo "  推奨拡張機能数: $recommended_count"
        else
            echo "  推奨拡張機能リスト: 未作成"
        fi
        
        if [ -f "$installed_file" ]; then
            local installed_count=$(wc -l < "$installed_file")
            echo "  インストール済み拡張機能数: $installed_count"
        else
            echo "  インストール済みリスト: 未保存"
        fi
        
        # 差分を表示
        if [ -f "$recommended_file" ] && [ -f "$installed_file" ]; then
            local temp_diff="/tmp/cursor_status_diff.txt"
            local diff_count=$(calculate_extensions_diff "$recommended_file" "$installed_file" "$temp_diff")
            echo "  未インストールの推奨拡張機能数: $diff_count"
            
            if [ "$diff_count" -gt 0 ] && [ "$diff_count" -le 10 ]; then
                echo "  未インストールの拡張機能:"
                cat "$temp_diff" | while read -r extension; do
                    echo "    - $extension"
                done
            fi
            rm -f "$temp_diff"
        fi
    fi
    
    echo ""
    log_success "=== 拡張機能の管理状況表示完了 ==="
}

# 使用方法の表示（更新版）
show_usage() {
    echo "使用方法: $0 [オプション]"
    echo ""
    echo "このスクリプトは VS Code と Cursor の設定を統合的に管理します"
    echo ""
    echo "オプション:"
    echo "  --backup        現在の設定をdotfilesにバックアップ"
    echo "  --diff          設定の変更差分を表示"
    echo "  --status        拡張機能の管理状況を表示"
    echo "  --vscode-only   VS Code設定のみを適用"
    echo "  --cursor-only   Cursor設定のみを適用"
    echo "  --help          このヘルプを表示"
    echo ""
    echo "拡張機能の管理について:"
    echo "  - 推奨拡張機能は recommended-extensions.txt で管理"
    echo "  - インストール済みは installed-extensions.txt に保存"
    echo "  - 差分のみをインストールするので効率的"
    echo ""
    echo "例:"
    echo "  $0                    # 全体セットアップを実行"
    echo "  $0 --backup           # 現在の設定をバックアップ"
    echo "  $0 --status           # 拡張機能の状況確認"
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
    echo "  （拡張機能差分管理対応版）"
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
        --status)
            show_extensions_status
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
    log_info "拡張機能の状況確認: $0 --status"
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
