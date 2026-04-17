---
name: add-product
description: >
  デジタルゲームとして必要な機能を追加する。
  「機能を追加」「SNS連携を追加」「リザルト画面に追加」
  「add-product.mdを実装」と言われたときに使用。
---

## 読むファイル
- `docs/temp/add-product.md`（なければ `docs/temp/*.md` を確認）
- `docs/SYSTEM_SPEC.md`（UI要素・物理パラメータ）
- `docs/GAME_FLOW.md`（ゲーム進行順序）

## 手順
1. `docs/temp/add-product.md` と関連仕様書を読む
2. 実装計画を提示 → **人間の承認を待つ**
3. 実装
4. `/run-tests` スキルでテストを実行（テストファイルが存在する場合のみ）
5. ログに記録・削除
   - `docs/product-log.md` に変更サマリーを追記（`cat >>` のみ）
   - `rm docs/temp/add-product.md`

詳細ルールは `references/workflow.md` を参照。
