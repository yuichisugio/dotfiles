# dotfiles

このリポジトリは、macOS環境での開発環境を効率的にセットアップするためのdotfiles管理システムです。シェル環境、Git設定、VS Code/Cursor エディタ設定、およびAI開発支援ツールの設定を統合的に管理します。

## 🎯 概要

このdotfilesは以下の開発環境を自動化します：

- **シェル環境**: zsh設定（履歴管理、補完、シンタックスハイライト、プロンプト）
- **Git環境**: Git設定、エイリアス、グローバルignore設定
- **エディタ環境**: VS Code・Cursor の統一設定
- **開発ツール**: Node.js、Python、パッケージマネージャーの設定
- **AI開発**: Claude AI を使用したTDD開発手法の設定

## 📁 ファイル構成

```
dotfiles/
├── .zshrc                          # zsh メイン設定ファイル
├── .gitconfig                      # Git 設定ファイル
├── .gitignore_global              # グローバル gitignore
├── .gitignore                     # リポジトリ用 gitignore
├── .claude/                       # Claude AI 設定
│   ├── CLAUDE.md                  # TDD開発手法の指針
│   └── settings.json              # Claude設定
├── .zsh/                          # zsh関連設定
│   └── aliases.zsh                # エイリアス定義
├── .github/                       # GitHub Actions
│   └── workflows/
│       └── ci.yml                 # CI設定（空ファイル）
├── vscode/                        # VS Code 設定
│   ├── settings.json              # エディタ設定
│   ├── keybindings.json           # キーバインド設定
│   ├── installed-extensions.txt   # インストール済み拡張機能
│   └── recommended-extensions.txt # 推奨拡張機能
├── cursor/                        # Cursor 設定
│   ├── settings.json              # エディタ設定
│   ├── keybindings.json           # キーバインド設定
│   ├── installed-extensions.txt   # インストール済み拡張機能
│   └── recommended-extensions.txt # 推奨拡張機能
└── shell-scripts/                 # インストールスクリプト
    ├── install.sh                 # メイン環境セットアップ
    ├── setup-cursor-vscode.sh     # エディタ設定セットアップ
    └── update-vscode-cursor-extensions-list.sh # 拡張機能リスト更新
```

## 🚀 クイックスタート

### 1. 基本環境のセットアップ

```bash
# 1. ホームディレクトリ以外の場所でclone
cd ~/Documents/VSCode  # お好みの場所
git clone https://github.com/yuichisugio/dotfiles.git
cd dotfiles

# 2. メイン環境をセットアップ
chmod +x shell-scripts/install.sh
./shell-scripts/install.sh

# 3. 設定を反映
source ~/.zshrc
```

### 2. エディタ環境のセットアップ

```bash
# VS Code・Cursor の設定をセットアップ
chmod +x shell-scripts/setup-cursor-vscode.sh
./shell-scripts/setup-cursor-vscode.sh
```

## 📋 各設定ファイルの詳細説明

### シェル環境設定

#### `.zshrc`
zshの包括的な設定ファイル。以下の機能を含みます：

- **履歴管理**: 重複削除、リアルタイム共有、実行時間記録
- **補完システム**: 大文字小文字を区別しない補完、色分け表示
- **シンタックスハイライト**: コマンド、エイリアス、パス等の色分け
- **プロンプト設定**: カスタムプロンプト表示
- **開発ツール設定**: nvm、pnpm、conda環境の自動設定
- **パス設定**: Homebrew、Node.js等のパス設定

#### `.zsh/aliases.zsh`
効率的な開発作業のためのエイリアス集：

- **Git操作**: `gs` (git status)、`ga` (git add .)、`gc` (git commit) など
- **ナビゲーション**: `..` (cd ..)、`ll` (ls -alF) など
- **開発ツール**: `nrd` (npm run dev)、`prd` (pnpm run dev) など
- **ユーティリティ関数**: `mkcd` (mkdir + cd)、`port` (ポート使用確認) など

### Git環境設定

#### `.gitconfig`
Git の包括的な設定：

- **ユーザー設定**: 名前、メール、エディタ設定
- **エイリアス**: 頻繁に使用するGitコマンドの短縮形
- **色分け設定**: ブランチ、diff、ステータスの色分け
- **プッシュ・プル設定**: デフォルトブランチ、リベース設定
- **URL設定**: GitHub用のSSH設定
- **Git LFS設定**: 大容量ファイル管理

#### `.gitignore_global`
プロジェクト共通で除外すべきファイル：

- **OS関連**: `.DS_Store`、`Thumbs.db` など
- **エディタ**: Vim、Emacs のテンポラリファイル
- **開発環境**: `node_modules`、`.env*`、テストカバレッジファイル
- **アーカイブ・実行ファイル**: `.zip`、`.exe` など

### エディタ設定（VS Code / Cursor）

#### `settings.json`
エディタの統一設定：

- **フォーマット設定**: Prettier による自動フォーマット、タブサイズ2
- **ファイル管理**: 自動保存、ファイル入れ子表示
- **Git統合**: 自動フェッチ、スマートコミット
- **拡張機能設定**: ESLint、Prettier、Copilot等の設定
- **UI設定**: アイコンテーマ、ミニマップ無効化
- **Cursor固有**: AI補完、差分表示、ターミナル設定

#### `keybindings.json`
効率的なキーバインド設定：

- **タブ切り替え**: `Cmd+1~9` でタブ切り替え
- **ターミナル操作**: `Cmd+L` でクリア、`F1` でフォーカス
- **パネル操作**: `Cmd+H` で最大化、`Cmd+Shift+P` でターミナルフォーカス

#### 拡張機能管理
- `installed-extensions.txt`: 現在インストール済みの拡張機能一覧
- `recommended-extensions.txt`: 推奨拡張機能一覧（Prettier、ESLint、GitLens など）

### AI開発支援設定

#### `.claude/CLAUDE.md`
Claude AI を使用したテスト駆動開発の指針：

- **TDD原則**: テスト先行開発、実装前のテスト作成
- **品質基準**: C0 85%以上、C1・C2 80%以上のカバレッジ目標
- **テスト設計**: 正常系・異常系・境界値テストの必須実装
- **禁止事項**: `as any` の使用禁止
- **開発フロー**: テスト→実装→リファクタリングのサイクル

## 🔧 セットアップスクリプト詳細

### `install.sh`
メイン環境のセットアップスクリプト：

- **安全なバックアップ**: 既存設定の自動バックアップ
- **シンボリックリンク作成**: 設定ファイルの適切なリンク
- **ディレクトリ構造確認**: 必要なディレクトリの自動作成
- **エラーハンドリング**: 各ステップでの詳細なエラー報告

### `setup-cursor-vscode.sh`
エディタ環境の統合セットアップ：

- **設定同期**: VS Code と Cursor の設定を統一
- **拡張機能管理**: 必要な拡張機能の自動インストール
- **バックアップ機能**: 既存設定の安全な保管
- **設定検証**: インストール後の設定確認

### `update-vscode-cursor-extensions-list.sh`
拡張機能リストの管理：

- **自動更新**: 現在の拡張機能リストを自動生成
- **同期機能**: VS Code と Cursor 間での拡張機能同期
- **推奨機能**: 必要な拡張機能の推奨リスト生成

## 🛠 カスタマイズ

### 個人設定の追加

個人固有の設定は以下のファイルで管理：

```bash
# 個人用 zsh 設定
~/.zshrc.local

# プロジェクト固有設定
~/.zsh/projects.zsh
```

### 拡張機能の管理

```bash
# 拡張機能リストの更新
./shell-scripts/update-vscode-cursor-extensions-list.sh
```

## 🔍 トラブルシューティング

### よくある問題

1. **権限エラー**: `chmod +x` でスクリプトに実行権限を付与
2. **パスの問題**: `source ~/.zshrc` で設定を再読み込み
3. **バックアップの復元**: タイムスタンプ付きバックアップから復元可能
4. **拡張機能の問題**: エディタの再起動で解決することが多い

### ログの確認

スクリプト実行時の詳細ログで問題を特定：

```bash
# 詳細ログでスクリプト実行
bash -x ./shell-scripts/install.sh
```

## 📈 継続的改善

このdotfilesは継続的に改善されています：

- **定期的な設定見直し**: 開発効率向上のための設定調整
- **新機能の追加**: 新しい開発ツールの統合
- **セキュリティ更新**: 設定ファイルのセキュリティ強化
- **ドキュメント改善**: 使いやすさの向上

## 📄 ライセンス

このプロジェクトはMITライセンスの下で公開されています。詳細は [LICENSE](LICENSE) ファイルを参照してください。

---

**注意**: このdotfilesはmacOS環境での使用を前提としています。他のOS環境での使用時は適切な調整が必要な場合があります。
