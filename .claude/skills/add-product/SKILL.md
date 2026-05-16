---
name: add-product
description: >
  デジタルゲームとして必要な機能を追加する。
  「機能を追加」「SNS連携を追加」「リザルト画面に追加」
  「add-product.mdを実装」と言われたときに使用。
---

## モデル分担
- **調査フェーズ**（手順 1）: `Agent` ツール（`model=opus`）に委譲して仕様書・ゲームフローを読む
- **実装フェーズ**（手順 2〜）: デフォルトモデルで計画提示・実装を行う

## 読むファイル
- `docs/temp/add-product.md`（なければ `docs/temp/*.md` を確認）
- `docs/SYSTEM_SPEC.md`（UI要素・物理パラメータ）
- `docs/GAME_FLOW.md`（ゲーム進行順序）

## 手順
1. `docs/temp/add-product.md` と関連仕様書を読む
2. 実装計画を提示 → **人間の承認を待つ**
3. 実装
4. GDScript を変更した場合、`/gdscript-check` スキルでセルフチェックを実行する
5. ゲームロジックを変更・追加した場合、対応するテストケースを `tests/` のファイルに追加・修正する。テストファイルが存在しない場合は `/add-tests` スキルを参考に新規作成する。その後 `/run-tests` スキルで実行
5. ログに記録・削除
   - `docs/product-log.md` に変更サマリーを追記（`cat >>` のみ）
   - `rm docs/temp/add-product.md`

詳細ルールは `references/workflow.md` を参照。
