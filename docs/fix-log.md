# Fix Log

バグ修正の履歴。`/fix-bug` スキル完了時にAIが追記する。

---

## 2026-04-08: カード[7] 3枚ブロック差し込み — カード重なりバグ

**症状**: カード[7]の能力発動後にカードが重なって操作不能になる

**原因**: `set_block_center_selectable`（UI）と `ability_insert_block`（ロジック）で、ブロックの左端がギャップ右側カードと一致するケース（`j == gap_i + 1`）が除外されていなかった。

- `j == gap_i + 1` を選択 → `block_left = gap_right_card` → ブロック除去後に `gap_right_card` が消え `new_i = -1`
- アニメーションステップがおかしな順序で計算され、表示が壊れた状態でゲームがスタック

**修正**:
- `DeckDisplay.gd:set_block_center_selectable` — `adjacent_to_gap` に `j == gap_i + 1` を追加（UI側でそもそも選択不可にする）
- `Deck.gd:ability_insert_block` — `j == i + 1` を除外条件に追加（防御的バリデーション）

---

## 2026-04-16: スタートボタン押下でゲームが起動しないバグ

**症状**: タイトル画面のスタートボタンを押してもゲームが起動しない

**原因**: `InsertionArrow.gd`（当日追加した新規ファイル）が Godot のグローバルクラスキャッシュ（`.godot/global_script_class_cache.cfg`）に登録されていなかった。

- Godot 4 は `class_name` を持つスクリプトをキャッシュに登録することで他スクリプトからの参照を解決する
- キャッシュ未登録のため `DeckDisplay.gd` 内の `InsertionArrow.new(idx)` がパースエラーとなり、DeckDisplay スクリプト全体が機能しない状態に
- スタートボタン押下時に `deck_display.reset()` が失敗し、ゲーム開始処理が止まっていた

**修正**:
- `.godot/global_script_class_cache.cfg` に `InsertionArrow`（`base: Node2D`、`path: res://scripts/InsertionArrow.gd`）を追記

---

## 2026-04-16: カード[7] 3枚ブロック差し込み — 能力発動後に3枚消失するバグ

**症状**: カード[7]の能力発動後にカードが3枚消えて6枚表示になり、ゲームが進行不可になる

**根本原因** (2件):

1. **Main.gd `_compute_animation_steps` の `d.find` 対象ミス** (今回の主因):
   - 同日の change-card 作業でブロック中央を target1、ギャップ右側を target2 に変更したが、
     ブロック除去後の `var new_i = d.find(target1)` の行を更新し忘れた
   - `target1`（ブロック中央）は既に `d` から除去済みのため常に -1 を返す
   - Godot 4 の `Array.insert(-1, ...)` は失敗し、ブロック3枚が animation deck に戻らない
   - step deck が8枚→5枚になり、final deck = 6枚で表示固定

2. **Deck.gd `ability_insert_block` の不完全なロールバック** (潜在バグ):
   - ブロック3枚除去後に `new_i == -1` のとき `return false` するだけで3枚を戻していなかった
   - 上位バリデーション（`j == i±1` 排除）で通常は防止されるが、万が一すり抜けた場合に山札が永久的に3枚少なくなる

**修正**:
- `Main.gd:_compute_animation_steps` — `d.find(target1)` → `d.find(target2)` に修正。また `new_i == -1` の場合はブロックをロールバックする防御コードを追加
- `Deck.gd:ability_insert_block` — `new_i == -1` のとき3枚をロールバックしてから `return false` するよう修正
