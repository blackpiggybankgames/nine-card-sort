---
name: change-card
description: カード能力の変更・追加・バランス調整
---
## 読むファイル
- docs/temp/ability-spec.md があれば読む（なければ docs/temp/*.md を確認）
- config/game_balance.json（cardsセクション）
- tests/test_abilities.gd

## 手順
1. docs/temp/ の一時ドキュメントを読む
2. 変更計画を提示し承認を待つ
3. 実装
4. テスト更新・実行
5. game_balance.json 更新
6. 一時ドキュメントを本体に統合し削除
   - `cat docs/temp/xxx.md >> 統合先ファイル` で末尾に追記
   - ファイル全体を読み込んで書き直さないこと
   - 追記後 `rm docs/temp/xxx.md` で削除

## 注意
- 面白さに関わる変更は選択肢2-3個を提示し人間が決定
- 計画を提示して人間の承認を待つ。承認なしに実装しない
