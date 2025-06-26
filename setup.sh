#!/bin/bash
# dotfiles簡易セットアップスクリプト

set -e

# カラー出力用
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}dotfiles setup script${NC}"
echo "========================================"

# dotfilesディレクトリのパス
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Dotfiles directory: $DOTFILES_DIR"

# シンボリックリンクを作成する関数
create_symlink() {
    local source="$1"
    local target="$2"
    local description="$3"
    
    if [ -L "$target" ]; then
        echo -e "${YELLOW}Removing existing symlink: $target${NC}"
        rm "$target"
    elif [ -e "$target" ]; then
        echo -e "${YELLOW}Backing up existing file: $target -> $target.backup${NC}"
        mv "$target" "$target.backup"
    fi
    
    ln -sf "$source" "$target"
    echo -e "${GREEN}✓ Created symlink: $description${NC}"
}

# 必要なディレクトリを作成
mkdir -p ~/.ssh

# シンボリックリンクを作成
echo ""
echo "Creating symlinks..."
create_symlink "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc" ".zshrc"
create_symlink "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig" ".gitconfig"
create_symlink "$DOTFILES_DIR/.gitignore_global" "$HOME/.gitignore_global" ".gitignore_global"
create_symlink "$DOTFILES_DIR/.claude" "$HOME/.claude" ".claude"
create_symlink "$DOTFILES_DIR/.ssh_config" "$HOME/.ssh/config" ".ssh/config"

echo ""
echo -e "${GREEN}✓ dotfiles setup completed!${NC}"
echo ""
echo "Next steps:"
echo "1. Restart your terminal or run: source ~/.zshrc"
echo "2. Verify git settings: git config --global --list"
echo "3. Test SSH connection: ssh -T git@github.com"