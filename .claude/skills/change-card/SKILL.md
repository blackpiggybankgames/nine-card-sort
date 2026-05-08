---
name: change-card
description: >
  カード能力の変更・追加・バランス調整を行う。
  「カード能力を変更」「アビリティを追加」「バランス調整」
  「change-card.mdを実装」と言われたときに使用。
---

## 読むファイル
- `docs/temp/change-card.md`（なければ `docs/temp/*.md` を確認）
- `docs/ABILITIES.md`（現在の確定能力一覧）
- `config/game_balance.json`（cards セクション）

## 手順
1. `docs/temp/change-card.md` と `docs/ABILITIES.md` を読む
2. 変更計画を提示 → **人間の承認を待つ**
3. 実装（`game_balance.json` 更新を含む）
4. GDScript を変更した場合、`/gdscript-check` スキルでセルフチェックを実行する
5. 変更したロジックに対応するテストファイルを `tests/` から特定し、テストケースを追加・修正する。テストファイルが存在しない場合は `/add-tests` スキルを参考に新規作成する。その後 `/run-tests` スキルで実行
5. ログに記録・削除
   - `docs/abilities-log.md` に変更サマリーを追記（`cat >>` のみ）
   - `docs/ABILITIES.md` は**触らない**（確定時のみ人間が判断）
   - `rm docs/temp/change-card.md`

詳細ルールは `references/workflow.md` を参照。