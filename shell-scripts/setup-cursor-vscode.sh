#!/bin/bash

# unified-dotfiles-setup.sh - VS Code & Cursor 統合設定管理スクリプト（WSL対応版）
# このスクリプトは、VS CodeとCursorの設定を統合的に管理し、
# WSL環境でも適切に動作するように拡張されています

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
# システム環境検出関数（WSL対応強化）
# =============================================================================

# 環境タイプを検出する関数
detect_environment() {
    if [[ -f /proc/sys/fs/binfmt_misc/WSLInterop ]]; then
        echo "wsl"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "msys"* ]] || [[ "$OSTYPE" == "win"* ]] || [[ "$OSTYPE" == "cygwin"* ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

# WSL環境での追加情報を取得
get_wsl_info() {
    if [[ $(detect_environment) == "wsl" ]]; then
        # WSLのバージョンを確認
        WSL_VERSION=$(wsl.exe -l -v 2>/dev/null | grep -E "^\s*\*" | awk '{print $4}' || echo "unknown")
        # Windowsのユーザー名を取得
        WINDOWS_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r' || whoami)
        WINDOWS_HOME="/mnt/c/Users/$WINDOWS_USER"
        
        log_info "WSL Version: $WSL_VERSION"
        log_info "Windows User: $WINDOWS_USER"
        log_info "Windows Home: $WINDOWS_HOME"
    fi
}

# アプリケーションがインストールされているかチェックする関数（WSL対応）
check_application_exists() {
    local app_name="$1"
    local environment=$(detect_environment)
    
    if [[ "$environment" == "wsl" ]]; then
        # WSL環境では、Windows側のアプリケーションをチェック
        case "$app_name" in
            "code")
                # VS Codeの実行可能ファイルをチェック
                if command -v code &> /dev/null || command -v code.exe &> /dev/null; then
                    log_success "VS Code が見つかりました（WSL統合）"
                    return 0
                elif [[ -f "/mnt/c/Program Files/Microsoft VS Code/bin/code" ]] || \
                     [[ -f "$WINDOWS_HOME/AppData/Local/Programs/Microsoft VS Code/bin/code" ]]; then
                    log_success "VS Code が見つかりました（Windows側）"
                    return 0
                fi
                ;;
            "cursor")
                # Cursorの実行可能ファイルをチェック
                if command -v cursor &> /dev/null || command -v cursor.exe &> /dev/null; then
                    log_success "Cursor が見つかりました（WSL統合）"
                    return 0
                elif [[ -f "/mnt/c/Program Files/Cursor/bin/cursor" ]] || \
                     [[ -f "$WINDOWS_HOME/AppData/Local/Programs/cursor/cursor.exe" ]]; then
                    log_success "Cursor が見つかりました（Windows側）"
                    return 0
                fi
                ;;
        esac
        
        log_warning "$app_name がインストールされていません。Windows側でインストールしてください。"
        return 1
    else
        # 通常の環境でのチェック
        if command -v "$app_name" &> /dev/null; then
            log_success "$app_name が見つかりました"
            return 0
        else
            log_warning "$app_name がインストールされていません。スキップします。"
            return 1
        fi
    fi
}

# =============================================================================
# 設定ディレクトリパス取得関数（WSL対応）
# =============================================================================

# VS Codeの設定ディレクトリパスを取得
get_vscode_config_path() {
    local environment=$(detect_environment)
    
    case $environment in
        "wsl")
            # WSL環境では、Windows側の設定ディレクトリを使用
            echo "$WINDOWS_HOME/AppData/Roaming/Code/User"
            ;;
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
            log_error "サポートされていない環境: $environment"
            return 1
            ;;
    esac
}

# Cursorの設定ディレクトリパスを取得
get_cursor_config_path() {
    local environment=$(detect_environment)
    
    case $environment in
        "wsl")
            # WSL環境では、Windows側の設定ディレクトリを使用
            echo "$WINDOWS_HOME/AppData/Roaming/Cursor/User"
            ;;
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
            log_error "サポートされていない環境: $environment"
            return 1
            ;;
    esac
}

# dotfilesリポジトリのパス取得
get_dotfiles_path() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local current_dir="$script_dir"
    
    # dotfilesのルートディレクトリを探索
    while [ "$current_dir" != "/" ]; do
        if [ -f "$current_dir/.gitconfig" ] || [ -f "$current_dir/.zshrc" ] || \
           [ -d "$current_dir/vscode" ] || [ -d "$current_dir/cursor" ]; then
            echo "$current_dir"
            return 0
        fi
        
        # 親ディレクトリに移動
        current_dir="$(dirname "$current_dir")"
    done
    
    # 見つからない場合は、スクリプトディレクトリの親ディレクトリを返す
    local basename_dir="$(basename "$script_dir")"
    if [[ "$basename_dir" == "shell-scripts" || "$basename_dir" == "scripts" ]]; then
        echo "$(dirname "$script_dir")"
    else
        echo "$script_dir"
    fi
}

# =============================================================================
# WSL環境での特別な処理
# =============================================================================

# WSL環境でのVS Code/Cursor実行コマンドのセットアップ
setup_wsl_commands() {
    local environment=$(detect_environment)
    
    if [[ "$environment" != "wsl" ]]; then
        return 0
    fi
    
    log_step "WSL環境用のコマンドエイリアスを設定中..."
    
    # VS Code用のエイリアス作成
    if ! command -v code &> /dev/null; then
        # codeコマンドのシンボリックリンクを作成
        if [[ -f "/mnt/c/Program Files/Microsoft VS Code/bin/code" ]]; then
            sudo ln -sf "/mnt/c/Program Files/Microsoft VS Code/bin/code" /usr/local/bin/code
        elif [[ -f "$WINDOWS_HOME/AppData/Local/Programs/Microsoft VS Code/bin/code" ]]; then
            sudo ln -sf "$WINDOWS_HOME/AppData/Local/Programs/Microsoft VS Code/bin/code" /usr/local/bin/code
        fi
    fi
    
    # Cursor用のエイリアス作成
    if ! command -v cursor &> /dev/null; then
        # cursorコマンドのシンボリックリンクを作成
        if [[ -f "/mnt/c/Program Files/Cursor/bin/cursor" ]]; then
            sudo ln -sf "/mnt/c/Program Files/Cursor/bin/cursor" /usr/local/bin/cursor
        elif [[ -f "$WINDOWS_HOME/AppData/Local/Programs/cursor/cursor.exe" ]]; then
            # シェルラッパーを作成
            sudo tee /usr/local/bin/cursor > /dev/null <<'EOF'
#!/bin/bash
exec "$WINDOWS_HOME/AppData/Local/Programs/cursor/cursor.exe" "$@"
EOF
            sudo chmod +x /usr/local/bin/cursor
        fi
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
        # WSL環境では--list-extensionsはWindows側で実行
        local environment=$(detect_environment)
        if [[ "$environment" == "wsl" ]]; then
            local extensions_backup="$backup_dir/extensions-$timestamp.txt"
            if [[ "$app_name" == "code" ]]; then
                code.exe --list-extensions > "$extensions_backup" 2>/dev/null || true
            elif [[ "$app_name" == "cursor" ]]; then
                cursor.exe --list-extensions > "$extensions_backup" 2>/dev/null || true
            fi
            log_success "拡張機能リストをバックアップしました: $extensions_backup"
        elif command -v "$app_name" &> /dev/null; then
            local extensions_backup="$backup_dir/extensions-$timestamp.txt"
            "$app_name" --list-extensions > "$extensions_backup" 2>/dev/null || true
            log_success "拡張機能リストをバックアップしました: $extensions_backup"
        fi
    else
        log_info "$app_name の既存設定が見つかりません。新規セットアップを行います。"
    fi
}

# =============================================================================
# 設定ファイル管理関数群（WSL対応）
# =============================================================================

# シンボリックリンクを安全に作成する関数（WSL対応）
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
    
    # WSL環境では通常のコピーを使用（シンボリックリンクはWindows側で問題を起こす可能性がある）
    local environment=$(detect_environment)
    if [[ "$environment" == "wsl" ]]; then
        cp "$source_file" "$target_file"
        log_success "$file_description をコピーしました（WSL環境）"
    else
        # 通常の環境ではシンボリックリンクを作成
        ln -s "$source_file" "$target_file"
        log_success "$file_description のシンボリックリンクを作成しました"
    fi
}

# =============================================================================
# 拡張機能管理関数群（WSL対応）
# =============================================================================

# 現在インストールされている拡張機能を保存する関数（WSL対応）
save_installed_extensions() {
    local app_name="$1"
    local output_file="$2"
    local environment=$(detect_environment)
    
    log_step "$app_name の現在の拡張機能リストを保存中..."
    
    # ディレクトリが存在しない場合は作成
    mkdir -p "$(dirname "$output_file")"
    
    # WSL環境での拡張機能リスト取得
    if [[ "$environment" == "wsl" ]]; then
        if [[ "$app_name" == "code" ]]; then
            if command -v code.exe &> /dev/null; then
                code.exe --list-extensions > "$output_file" 2>/dev/null || true
            else
                log_error "VS Code (Windows側) が見つかりません"
                return 1
            fi
        elif [[ "$app_name" == "cursor" ]]; then
            if command -v cursor.exe &> /dev/null; then
                cursor.exe --list-extensions > "$output_file" 2>/dev/null || true
            else
                log_error "Cursor (Windows側) が見つかりません"
                return 1
            fi
        fi
    else
        # 通常の環境での拡張機能リスト取得
        if command -v "$app_name" &> /dev/null; then
            "$app_name" --list-extensions > "$output_file"
        else
            log_error "$app_name が見つからないため、拡張機能リストを保存できません"
            return 1
        fi
    fi
    
    if [ -f "$output_file" ]; then
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
    fi
}

# =============================================================================
# メイン設定関数（WSL対応）
# =============================================================================

# VS Code設定の包括的セットアップ（WSL対応版）
setup_vscode() {
    local app_name="code"
    local environment=$(detect_environment)
    
    # VS Codeのインストール確認
    if ! check_application_exists "$app_name"; then
        if [[ "$environment" == "wsl" ]]; then
            log_info ""
            log_info "Windows側でVS Codeをインストールし、Remote - WSL拡張機能を追加してください"
            log_info "インストール後、このスクリプトを再実行してください"
        fi
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
    
    # WSL環境での追加設定
    if [[ "$environment" == "wsl" ]]; then
        log_info "WSL環境用の追加設定を適用中..."
        
        # WSL用の推奨拡張機能を自動的にインストール
        log_info "Remote - WSL拡張機能の確認..."
        if code.exe --list-extensions 2>/dev/null | grep -q "ms-vscode-remote.remote-wsl"; then
            log_success "Remote - WSL拡張機能は既にインストールされています"
        else
            log_info "Remote - WSL拡張機能をインストール中..."
            code.exe --install-extension ms-vscode-remote.remote-wsl --force
        fi
    fi
    
    log_success "=== VS Code 設定セットアップ完了 ==="
}

# Cursor設定の包括的セットアップ（WSL対応版）
setup_cursor() {
    local app_name="cursor"
    local environment=$(detect_environment)
    
    # Cursorのインストール確認
    if ! check_application_exists "$app_name"; then
        if [[ "$environment" == "wsl" ]]; then
            log_info ""
            log_info "Windows側でCursorをインストールしてください"
            log_info "インストール後、このスクリプトを再実行してください"
        fi
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
    
    log_success "=== Cursor 設定セットアップ完了 ==="
}

# =============================================================================
# 使用方法の表示（WSL対応版）
# =============================================================================

show_usage() {
    echo "使用方法: $0 [オプション]"
    echo ""
    echo "このスクリプトは VS Code と Cursor の設定を統合的に管理します"
    echo "WSL環境にも対応しています"
    echo ""
    echo "オプション:"
    echo "  --setup-wsl     WSL環境用のコマンドセットアップ"
    echo "  --vscode-only   VS Code設定のみを適用"
    echo "  --cursor-only   Cursor設定のみを適用"
    echo "  --help          このヘルプを表示"
    echo ""
    echo "WSL環境での使用:"
    echo "  1. Windows側でVS Code/Cursorをインストール"
    echo "  2. VS CodeでRemote - WSL拡張機能をインストール"
    echo "  3. WSL内でこのスクリプトを実行"
    echo ""
    echo "例:"
    echo "  $0                    # 全体セットアップを実行"
    echo "  $0 --setup-wsl        # WSLコマンドのセットアップ"
    echo "  $0 --vscode-only      # VS Code設定のみを適用"
}

# =============================================================================
# メイン実行関数
# =============================================================================

main() {
    # スクリプト開始のアナウンス
    echo "========================================================"
    echo "  VS Code & Cursor 統合dotfiles管理スクリプト"
    echo "  （WSL対応版）"
    echo "========================================================"
    
    local environment=$(detect_environment)
    local dotfiles_dir=$(get_dotfiles_path)
    
    log_info "検出された環境: $environment"
    log_info "dotfilesディレクトリ: $dotfiles_dir"
    
    # WSL環境の場合、追加情報を表示
    if [[ "$environment" == "wsl" ]]; then
        get_wsl_info
    fi
    
    echo ""
    
    # コマンドライン引数の処理
    case "${1:-}" in
        --setup-wsl)
            setup_wsl_commands
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
    
    # WSL環境での初期セットアップ
    if [[ "$environment" == "wsl" ]]; then
        setup_wsl_commands
    fi
    
    # 統合セットアップの実行
    log_step "統合設定セットアップを開始します..."
    
    # 各アプリケーションの設定を順次実行
    setup_vscode
    echo ""
    setup_cursor
    
    # セットアップ完了のアナウンス
    echo ""
    echo "========================================================"
    log_success "統合dotfiles設定が完了しました！"
    echo "========================================================"
    
    # 環境別の再起動推奨
    if [[ "$environment" == "wsl" ]]; then
        log_info ""
        log_info "WSL環境での次のステップ:"
        log_info "1. Windows側でVS Code/Cursorを再起動"
        log_info "2. VS Code/Cursorから 'Remote-WSL: New Window' コマンドを実行"
        log_info "3. WSL環境内でプロジェクトを開く"
    else
        log_info "変更を適用するために、以下のアプリケーションを再起動してください:"
        check_application_exists "code" && echo "  - VS Code"
        check_application_exists "cursor" && echo "  - Cursor"
    fi
}

# =============================================================================
# エラーハンドリングとスクリプト実行
# =============================================================================

# エラーハンドリングの設定
trap 'log_error "スクリプト実行中にエラーが発生しました (行番号: $LINENO)"; exit 1' ERR

# メイン関数の実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
