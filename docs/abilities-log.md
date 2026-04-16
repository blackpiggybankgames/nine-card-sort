## 2026-04-02: 全カード能力の全面刷新

全9枚の能力を新設計に置き換え。

| カード | 旧能力 | 新能力 |
|-------|--------|--------|
| 1 | 引き上げ | ±1入れ替え（能力E） |
| 2 | 押し下げ | 3枚順繰り（能力I） |
| 3 | 隣接入替 | 全体リバース（能力D） |
| 4 | 2番目落とし | どかす（能力A） |
| 5 | 3番目引き出し | 上下入れ替え（能力H） |
| 6 | 下半分リバース | 2セット下送り（能力G） |
| 7 | ブロック入れ替え | 3枚ブロック差し込み（能力B） |
| 8 | フルリバース | 上下反転＋任意移動（能力F） |
| 9 | 合計送り | 4枚逆順（能力C） |

変更ファイル: scripts/Deck.gd, scripts/GameManager.gd, scripts/Main.gd, scripts/DeckDisplay.gd, config/game_balance.json, docs/content/card_assignments.md

## 2026-04-16: カード7「3枚ブロック差し込み」操作順序変更

**変更内容**: 2段階選択の順序を反転

- **変更前**: ①差し込み先（矢印） → ②ブロック中央カード
- **変更後**: ①ブロック中央カード → ②差し込み先（矢印、ブロックと重ならない位置のみ）

**変更理由**: プレイヤーの思考順（「このブロックをどこかに差し込みたい」）に合わせるため

**変更ファイル**:
- `scripts/Main.gd`: ステップ1・2のUI切り替えロジック、アニメーションステップのtarget1/target2入れ替え
- `scripts/DeckDisplay.gd`: `set_block_center_any_selectable()` 関数追加
- `scripts/Deck.gd`: `use_ability` card 7 の引数順を `ability_insert_block(target2, target1)` に変更
- `scripts/GameManager.gd`: コメント更新
