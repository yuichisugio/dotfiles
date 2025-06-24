# WSL環境でのdotfiles使用ガイド

このドキュメントでは、Windows Subsystem for Linux（WSL）環境でdotfilesを使用するための詳細な手順を説明します。

## 📋 前提条件

WSL環境でdotfilesを使用する前に、以下の準備が必要です：

### Windows側の準備

1. **WSL2のインストール**
   ```powershell
   # PowerShellを管理者権限で実行
   wsl --install
   ```

2. **VS Code/Cursorのインストール**
   - [VS Code](https://code.visualstudio.com/)をWindows側にインストール
   - [Cursor](https://cursor.sh/)をWindows側にインストール（オプション）

3. **Remote - WSL拡張機能**
   - VS Codeを起動し、拡張機能マーケットプレイスから「Remote - WSL」をインストール

### WSL側の準備

1. **基本的な開発ツール**
   ```bash
   # WSL内で実行
   sudo apt update
   sudo apt install -y git curl wget build-essential
   ```

2. **Zshのインストール**
   ```bash
   sudo apt install -y zsh zsh-syntax-highlighting zsh-autosuggestions
   ```

## 🚀 インストール手順

### 1. dotfilesのクローン

WSL環境内で以下のコマンドを実行します：

```bash
# WSLのホームディレクトリで実行
cd ~
git clone https://github.com/yourusername/dotfiles.git
cd dotfiles
```

### 2. インストールスクリプトの実行

```bash
# 実行権限を付与
chmod +x shell-scripts/install.sh
chmod +x shell-scripts/setup-cursor-vscode.sh

# メイン環境のセットアップ
./shell-scripts/install.sh

# エディタ設定のセットアップ
./shell-scripts/setup-cursor-vscode.sh
```

インストール中に以下のような質問が表示される場合があります：
- デフォルトシェルをzshに変更するか
- Windows側のVS Code設定を共有するか
- /etc/wsl.confを作成するか

### 3. シェルの再起動

```bash
# 新しいzshセッションを開始
exec zsh
```

## 🔧 WSL固有の機能

### パス変換ユーティリティ

WSL環境では、Windows/Linux間のパス変換用の関数が利用できます：

```bash
# WindowsパスをWSLパスに変換
winpath "C:\Users\YourName\Documents"
# 出力: /mnt/c/Users/YourName/Documents

# WSLパスをWindowsパスに変換
wslpath "/home/username/projects"
# 出力: \\wsl$\Ubuntu\home\username\projects
```

### Windowsアプリケーションとの統合

```bash
# Windows側のエクスプローラーで現在のディレクトリを開く
explorer .

# Windows側のVS Codeで現在のディレクトリを開く
code .

# クリップボードへのコピー
echo "Hello" | clip
```

### エイリアス

WSL環境では以下の追加エイリアスが利用できます：

- `clip`: Windows側のクリップボードへコピー
- `winhome`: Windowsのホームディレクトリへ移動

## 📁 ファイル共有とパーミッション

### Windows/WSL間のファイル共有

WSL2では、Windows側のファイルは `/mnt/c/` 以下にマウントされます：

```bash
# Windows側のドキュメントフォルダにアクセス
cd /mnt/c/Users/YourWindowsUsername/Documents
```

### パーミッションの注意点

WSL環境では、Windows側のファイルシステムとLinux側のファイルシステムでパーミッションの扱いが異なります。`/etc/wsl.conf` で適切に設定されています：

```ini
[automount]
options = "metadata,umask=22,fmask=11"
```

## 🛠 VS Code/Cursor の使用

### VS Codeの起動方法

1. **WSL内から起動**
   ```bash
   # プロジェクトディレクトリで実行
   code .
   ```

2. **Windows側から起動**
   - VS Codeを起動
   - `Ctrl+Shift+P` でコマンドパレットを開く
   - `Remote-WSL: New Window` を選択

### 拡張機能の管理

WSL環境では、拡張機能は以下の2つの場所にインストールされます：

- **ローカル（Windows側）**: UI関連の拡張機能
- **WSL側**: 言語サーバーやリンターなどの開発ツール

## 🔍 トラブルシューティング

### よくある問題と解決方法

1. **VS Codeがコマンドラインから起動しない**
   ```bash
   # WSLコマンドのセットアップを再実行
   ./shell-scripts/setup-cursor-vscode.sh --setup-wsl
   ```

2. **Git設定でのファイルモード警告**
   ```bash
   # WSL環境では自動的に設定されますが、手動で設定する場合
   git config --global core.filemode false
   ```

3. **パフォーマンスの問題**
   - Windows側のファイル（`/mnt/c/`）での作業は遅い
   - 可能な限りWSL側のファイルシステム（`~/`）で作業する

4. **WSLの再起動が必要な場合**
   ```powershell
   # PowerShellで実行
   wsl --shutdown
   # その後、WSLを再度起動
   ```

## 📝 設定のカスタマイズ

### WSL固有の設定

`~/.zshrc.local` ファイルを作成して、WSL環境固有の設定を追加できます：

```bash
# ~/.zshrc.local の例

# Docker Desktop for Windowsとの統合
export DOCKER_HOST=tcp://localhost:2375

# X11フォワーディングの設定（GUI アプリケーション用）
export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0

# Windows側のツールへのパス追加
export PATH="$PATH:/mnt/c/Program Files/Docker/Docker/resources/bin"
```

### Windows Terminal の設定

Windows Terminal を使用している場合、以下の設定を追加することで、より快適な環境を構築できます：

```json
{
    "profiles": {
        "list": [
            {
                "guid": "{your-wsl-guid}",
                "name": "WSL - Ubuntu",
                "source": "Windows.Terminal.Wsl",
                "startingDirectory": "//wsl$/Ubuntu/home/username",
                "fontFace": "Cascadia Code",
                "fontSize": 12,
                "colorScheme": "One Half Dark"
            }
        ]
    }
}
```

## 🔄 更新とメンテナンス

### dotfilesの更新

```bash
cd ~/dotfiles
git pull origin main

# 設定を再適用
./shell-scripts/install.sh
```

### WSL環境のアップグレード

```bash
# WSL内で実行
sudo apt update && sudo apt upgrade

# Windows側でWSLのアップデート
wsl --update
```

## 📚 関連リソース

- [WSL公式ドキュメント](https://docs.microsoft.com/ja-jp/windows/wsl/)
- [VS Code Remote Development](https://code.visualstudio.com/docs/remote/wsl)
- [WSL2のベストプラクティス](https://docs.microsoft.com/ja-jp/windows/wsl/compare-versions)

## 💡 Tips & Tricks

1. **プロジェクトの配置場所**
   - パフォーマンスを重視する場合は、WSL側（`~/projects/`）に配置
   - Windows側のツールとの互換性が必要な場合は、`/mnt/c/` 以下に配置

2. **ネットワークドライブへのアクセス**
   ```bash
   # Windows側でマウントされているネットワークドライブにアクセス
   cd /mnt/z/  # Zドライブの例
   ```

3. **WSL2でのポートフォワーディング**
   - WSL2内で起動したサーバーは、Windows側の `localhost` でアクセス可能

4. **メモリ使用量の調整**
   ```ini
   # %USERPROFILE%\.wslconfig
   [wsl2]
   memory=4GB
   processors=2
   ```

---

WSL環境でのdotfiles使用に関する質問や問題がある場合は、GitHubのIssuesで報告してください。
