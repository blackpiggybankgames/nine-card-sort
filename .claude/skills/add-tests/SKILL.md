---
name: add-tests
description: >
  ゲームロジックのテストコードを作成する。
  「テストを追加」「テストを書いて」「テストコードを実装」
  「add-tests.mdを実装」と言われたときに使用。
  前提: GUT（Godot Unit Test）が addons/gut/ に導入済みであること。
---

## モデル分担
- **調査フェーズ**（手順 1〜2）: `Agent` ツール（`model=opus`）に委譲してテスト対象の分析・計画立案を行う
- **実装フェーズ**（手順 3〜）: デフォルトモデルでテストコードを実装する

## 読むファイル
- `docs/temp/add-tests.md`（なければ `docs/temp/*.md` を確認）
- テスト対象のソースコード（`scripts/` 以下）
- `tests/`（既存テストの確認）

## 手順
1. テスト対象を特定する
   - 一時ドキュメントがあればそれを読む
   - なければ `scripts/` 以下のゲームロジック層を確認する
2. テスト計画を提示 → **人間の承認を待つ**
   - カバーする機能とテストファイル名の一覧を示す
3. テストコードを実装する
   - `tests/` ディレクトリに配置
   - ファイル名は `test_<機能名>.gd`（例: `test_game_state.gd`）
   - GUTの規約に従う（詳細は `references/gut_conventions.md`）
4. `/gdscript-check` スキルでセルフチェックを実行する
5. `/run-tests` スキルでテストを実行し、全件パスを確認する
5. 一時ドキュメントを削除
   - `rm docs/temp/add-tests.md`

詳細ルールは `references/workflow.md` を参照。
