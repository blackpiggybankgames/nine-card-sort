---
name: change-rules
description: ゲームルールの変更
---
## 読むファイル
- docs/temp/$ARGUMENTS があれば読む（なければ docs/temp/*.md を確認）
- docs/GAME_DESIGN.md（影響範囲把握）
- docs/TECHNICAL_SPEC.md
- tests/（関連テスト）

## 手順
1. docs/temp/ の一時ドキュメントを読む
2. GAME_DESIGN.md で影響範囲を把握
3. 影響するカード能力を洗い出す
4. 変更計画を提示し承認を待つ（影響カード一覧を含める）
5. 実装
6. テスト更新・`/run-tests` スキルで実行
7. GAME_DESIGN.md 更新
8. docs/adr/ に設計判断を記録
9. 一時ドキュメントを本体に統合し削除
   - `cat docs/temp/xxx.md >> 統合先ファイル` で末尾に追記
   - ファイル全体を読み込んで書き直さないこと

## 影響範囲チェックリスト
- 勝利条件 / 手番の流れ / 既存カード能力 / UI

## 注意
- ルール変更は全カード能力に波及しうる
- 面白さに関わる変更は選択肢2-3個を提示し人間が決定
- 計画を提示して人間の承認を待つ。承認なしに実装しない
