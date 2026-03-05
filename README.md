# Godot Game Template

Godot 4.3 game template for development with Claude Code

## 特徴

- ✅ Godot 4.3 対応
- ✅ Web (HTML5) エクスポート対応
- ✅ 設定ファイル管理 (JSON)
- ✅ ホットリロード対応（開発中に'R'キーで設定再読み込み）
- ✅ ドキュメント体系完備
- ✅ Claude Code との協働開発に最適化

## 開発環境

- **Engine**: Godot 4.3
- **Target**: Web (HTML5)
- **AI**: Claude Code
- **Environment**: WSL (Ubuntu) + Windows

## このテンプレートの使い方

### 1. GitHubでテンプレートから新規リポジトリ作成

1. このリポジトリページで "Use this template" をクリック
2. 新しいリポジトリ名を入力（例: `my-awesome-game`）
3. "Create repository" をクリック

### 2. ローカルにクローン
```bash
cd ~
git clone https://github.com/YOUR_USERNAME/your-new-game.git
cd your-new-game
```

### 3. Claude Code で開く
```bash
claude .
```

### 4. ドキュメント作成

Claude Code に指示:
```
"docs/DOCUMENTATION_STATUS.md を確認して、
 Phase 0 の必須ドキュメントを全て作成してください"
```

## Webビルド
```bash
# エクスポート
~/Godot_v4.3-stable_linux.x86_64 --headless --path . \
  --export-release "Web" ./build/web/index.html

# ローカルサーバー起動
cd build/web
python3 -m http.server 8000
```

Windows ブラウザで http://localhost:8000 にアクセス

## ディレクトリ構造
```
.
├── config/              # 設定ファイル (JSON)
│   └── game_balance.json
├── docs/                # ドキュメント
│   ├── DOCUMENTATION_STATUS.md
│   └── templates/
├── scenes/              # .tscn シーンファイル
├── scripts/             # GDScript
│   ├── autoload/        # Autoload (シングルトン)
│   ├── entities/        # ゲームオブジェクト
│   └── ui/              # UI要素
├── assets/              # 画像・音声・フォント
└── tests/               # テストスクリプト
```

## ドキュメント

- [Documentation Status](docs/DOCUMENTATION_STATUS.md) - ドキュメント作成状況
- その他のドキュメントは開発開始時にClaude Codeが作成

## ライセンス

MIT License
