# Claude Code プロジェクト指示

## 作業開始時の必須チェック

1. `docs/DOCUMENTATION_STATUS.md` を必ず確認
2. Phase 0 の未作成ドキュメントがあれば作成
3. `docs/PROJECT_STATUS.md` で進捗を確認（存在する場合）
4. `docs/CONSTRAINTS.md` で禁止事項を確認（存在する場合）

## ドキュメント作成ルール

- 新しいドキュメントを作成したら、必ず `DOCUMENTATION_STATUS.md` を更新
- 作成後、人間に確認を依頼

## このプロジェクトについて

- Godot 4.3 を使用したゲーム開発
- WSL環境で Claude Code を使用
- 設定は `config/game_balance.json` で管理
- 詳細は `docs/AI_CONTEXT.md` を参照（作成後）

## 禁止事項

- `.tscn` ファイルの直接編集は避ける（壊れやすい）
- ハードコードされた数値は `game_balance.json` に移動
- `~/.local/share/godot` への書き込み（サンドボックス制約）
