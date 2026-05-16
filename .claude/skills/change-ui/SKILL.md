---
name: change-ui
description: >
  UIやアニメーションの変更・調整を行う。
  「UIを変更」「レイアウトを変える」「画面を調整」「アニメーションを変更」
  「change-ui.mdを実装」と言われたときに使用。
---

## 読むファイル
- `docs/temp/change-ui.md`（なければ `docs/temp/*.md` を確認）
- `docs/SYSTEM_SPEC.md`（UI要素・物理パラメータ）
- `config/game_balance.json`（パラメータ管理）
- **ボタン関連の変更時は `references/button_debug.md` を必ず先に読む**（focus残留・テーマ継承・シェーダー干渉の罠を踏まないため）

## 手順
1. `docs/temp/change-ui.md` と `docs/SYSTEM_SPEC.md` を読む
2. 変更計画を提示 → **人間の承認を待つ**
3. 実装（`game_balance.json` 更新を含む場合あり）
4. GDScript を変更した場合、`/gdscript-check` スキルでセルフチェックを実行する
5. ゲームロジックを変更した場合、対応するテストケースを `tests/` のファイルに追加・修正する。UIのみの変更ならこのステップはスキップ可。その後 `/run-tests` スキルで実行（テストファイルが存在する場合のみ）
5. ログに記録・削除
   - `docs/ui-log.md` に変更サマリーを追記（`cat >>` のみ）
   - `rm docs/temp/change-ui.md`

詳細ルールは `references/workflow.md` を参照。
