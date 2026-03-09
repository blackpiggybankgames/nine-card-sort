# Fix Log / 修正履歴

**最終更新**: 2026-03-09

---

## 未対応

| ID | カテゴリ | 優先度 | 概要 | 報告日 |
|----|---------|--------|------|--------|
| - | - | - | - | - |

---

## 対応中

| ID | カテゴリ | 概要 | 担当 | 開始日 |
|----|---------|------|------|--------|
| - | - | - | - | - |

---

## 完了

| ID | カテゴリ | 概要 | 修正内容 | 完了日 |
|----|---------|------|----------|--------|
| FIX-001 | BUG | カードの能力が実行できない | シグナル接続方式に変更 | 2026-03-06 |
| FIX-002 | UI | カードの先頭を一番右にしたい | 位置・角度を反転 | 2026-03-06 |
| FIX-003 | BUG | 修正後もカードの能力が実行できない | _input方式でクリック検出 | 2026-03-06 |
| FIX-004 | UI | カードの重なりが逆 | z_indexを反転 | 2026-03-06 |
| FIX-005 | BUG | カード能力の結果が逆 | 手番開始時のカードを記憶して移動 | 2026-03-06 |
| FIX-006 | BUG | 4の能力で発動カード自身が対象になる | 発動前にカードを山札から除外 | 2026-03-06 |
| FIX-007 | BUG | 5の能力の真ん中が8枚で計算されている | 9枚の真ん中を基準に修正 | 2026-03-06 |
| FIX-008 | UI | 9の能力の2枚目選択ガイドがない | 1枚目選択後にペアのみ選択可能に | 2026-03-06 |
| FIX-009 | BUG | クリア判定が[1,2,3...]のみ | 循環ソートに対応 | 2026-03-06 |
| FIX-010 | UI | 9の能力で2枚目がハイライトされない | 2枚目選択時にもハイライト | 2026-03-06 |
| FIX-011 | UI | 9の能力で1枚目選択時に2枚目もハイライト | 1枚目選択時にペアもハイライト | 2026-03-06 |
| FIX-012 | UI | 選択可能カードのハイライトが不十分 | 選択可能時に背景も明るく表示 | 2026-03-06 |
| FIX-013 | UI | 能力9で1枚目選択後にペアがハイライトされない | 1枚目選択中はupdate_displayをスキップ | 2026-03-06 |
| FIX-014 | UI | カード選択時のハイライトが背景まで変わる | 枠線のみ黄色に変更 | 2026-03-06 |
| FIX-015 | UI | カード移動時にアニメーションがない | Tweenでアニメーション実装 | 2026-03-06 |
| FIX-016 | REQ | デバッグ用クリアボタンがない | debug_modeフラグと即クリアボタン追加 | 2026-03-06 |
| FIX-017 | BUG | クリア後の再開ができない | DeckDisplayにreset()追加、ゲーム開始時に呼び出し | 2026-03-06 |
| FIX-018 | DEPLOY | GitHub ActionsでWebエクスポートが失敗 | icon.svg追加、export_path設定、use_preset_export_path有効化 | 2026-03-07 |
| FIX-019 | UI | 日本語テキストが文字化け | Noto Sans JPフォント追加、テーマをコードで適用 | 2026-03-07 |
| FIX-020 | UI | スマホ画面で表示が崩れる | ストレッチモード設定、動的な画面サイズ対応 | 2026-03-07 |
| FIX-021 | BUG | クリア後のボタン操作・カード表示問題 | Card入力処理修正、クリア画面でカード表示 | 2026-03-08 |
| FIX-022 | BUG | 能力3（中央送り）の挿入位置が間違っている | insert位置をindex 4からindex 3に修正 | 2026-03-09 |

---

## 修正詳細

### FIX-001: カードの能力が実行できない

**報告**: DEBUG_FEEDBACK.md より
**優先度**: !!! 致命的
**原因**: Area2Dの`_input_event`仮想メソッドが正しく呼び出されていなかった
**修正**: `input_event`シグナルに接続する方式に変更
**変更ファイル**:
- `scripts/Card.gd`
  - `_ready()`で`input_event.connect(_on_input_event)`を追加
  - `_input_event`を`_on_input_event`にリネーム

---

### FIX-002: カードの先頭を一番右にしたい

**報告**: DEBUG_FEEDBACK.md より
**優先度**: !! 重要
**原因**: 扇状配置で一番上のカード（index 0）が左側に配置されていた
**修正**: 位置と角度の計算を反転
**変更ファイル**:
- `scripts/DeckDisplay.gd`
  - `card.position.x`の符号を反転（`-offset_from_center`）
  - `card.rotation_degrees`の符号を反転
  - z_indexはそのまま（重なり方は変更なし）

---

### FIX-003: 修正後もカードの能力が実行できない

**報告**: DEBUG_FEEDBACK.md より
**優先度**: !!! 致命的
**原因**: Area2Dの`input_event`シグナルが正しく発火しなかった
**修正**: `_input`メソッドでグローバルにマウスクリックを検出し、カード矩形内かチェック
**変更ファイル**:
- `scripts/Card.gd`
  - `_input(event)`メソッドを追加
  - `_is_point_inside(point)`メソッドを追加
  - マウス位置とカード矩形の判定で確実にクリック検出

---

### FIX-004: カードの重なりが逆

**報告**: DEBUG_FEEDBACK.md より
**優先度**: !! 重要
**原因**: z_indexがindexそのままだったため、index 0（一番上）が一番奥に表示
**修正**: z_indexを反転して、一番上のカードが一番手前に表示
**変更ファイル**:
- `scripts/DeckDisplay.gd`
  - `card.z_index = index` → `card.z_index = deck_data.size() - 1 - index`

---

### FIX-005: カード能力の結果が逆（1の能力で選択カードが一番下に行く）

**報告**: DEBUG_FEEDBACK.md より
**優先度**: !!! 致命的
**原因**: 能力発動後に「現在の一番上のカード」を一番下に移動していた。能力で一番上に移動したカードがすぐに一番下へ行ってしまう。
**修正**:
- 「手番開始時に一番上だったカード」（能力発動カード）を記憶
- 能力発動後、そのカードを一番下に移動
**変更ファイル**:
- `scripts/GameManager.gd`
  - `_execute_ability`に`original_top_card`引数を追加
  - `use_ability`と`select_target`から手番開始時のカードを渡す
- `scripts/Deck.gd`
  - `move_card_to_bottom(card_number)`関数を追加

---

### FIX-006: 4の能力で発動カード自身が対象になる

**報告**: DEBUG_FEEDBACK.md より
**優先度**: !!! 致命的
**原因**: 能力発動時に発動カード自身が山札に残っていたため、「上から2枚」に発動カード自身が含まれていた
**修正**:
- 能力発動前に発動カードを山札から取り除く
- 能力を実行（発動カードがない状態で）
- 能力発動後、発動カードを一番下に追加
**変更ファイル**:
- `scripts/GameManager.gd`
  - `_execute_ability`で発動前に`deck.remove_card()`を呼び出し
  - 能力実行後に`deck.add_card_to_bottom()`を呼び出し
- `scripts/Deck.gd`
  - `remove_card(card_number)`関数を追加
  - `add_card_to_bottom(card_number)`関数を追加
  - `MIDDLE_INDEX`定数を`get_middle_index()`関数に変更（8枚対応）

---

### FIX-007: 5の能力の真ん中が8枚で計算されている

**報告**: DEBUG_FEEDBACK.md より
**優先度**: !!! 致命的
**原因**: 真ん中参照能力で動的に計算していたため、発動カード除外後の8枚で計算されていた
**修正**:
- 真ん中参照能力（3, 5, 7）は「9枚の真ん中」を基準にする
- 発動カードは常にindex 0から除外されるので、9枚のindex 4は除外後index 3になる
- `MIDDLE_INDEX_8CARDS = 3`を定義し、真ん中参照能力で使用
**変更ファイル**:
- `scripts/Deck.gd`
  - `MIDDLE_INDEX_9CARDS = 4`（9枚の真ん中）を追加
  - `MIDDLE_INDEX_8CARDS = 3`（発動カード除外後の真ん中）を追加
  - 能力3, 5, 7で`MIDDLE_INDEX_8CARDS`を使用

---

### FIX-008: 9の能力の2枚目選択ガイドがない

**報告**: DEBUG_FEEDBACK.md より
**優先度**: !! 重要
**原因**: 能力9で2枚選択時に、2枚目のガイドがなく不親切
**修正**:
- 1枚目を選択したら、1枚目をハイライト表示
- 足して9になるペアのカードのみ選択可能に
- 指示テキストを「X を選択。Y を選んでください」に変更
**変更ファイル**:
- `scripts/GameManager.gd`
  - `ability9_second_selection`シグナルを追加
  - `select_target`で1枚目選択後にシグナル発火
- `scripts/Main.gd`
  - `_on_ability9_second_selection`ハンドラを追加
- `scripts/DeckDisplay.gd`
  - `set_card_highlighted`関数を追加

---

### FIX-009: クリア判定が[1,2,3...]のみ

**報告**: DEBUG_FEEDBACK.md より
**優先度**: !!! 致命的
**原因**: WIN_CONDITIONが[1,2,3,4,5,6,7,8,9]固定だった
**修正**:
- 循環ソートのチェックを実装
- [2,3,4,5,6,7,8,9,1]や[5,6,7,8,9,1,2,3,4]もクリアとして判定
- 各カードの次のカードが+1（9の次は1）になっていればソート済み
**変更ファイル**:
- `scripts/Deck.gd`
  - `is_cyclic_sorted()`関数を追加
  - `check_win()`で循環ソートをチェック

---

### FIX-010: 9の能力で2枚目がハイライトされない

**報告**: DEBUG_FEEDBACK.md より
**優先度**: !! 重要
**原因**: 2枚目選択時にハイライト処理がなかった
**修正**:
- `ability9_pair_selected`シグナルを追加
- 2枚目選択完了時にシグナル発火
- Main.gdで2枚目もハイライト表示
**変更ファイル**:
- `scripts/GameManager.gd`
  - `ability9_pair_selected`シグナルを追加
  - 2枚選択完了時にシグナル発火
- `scripts/Main.gd`
  - `_on_ability9_pair_selected`ハンドラを追加

---

### FIX-011: 9の能力で1枚目選択時に2枚目もハイライトされない

**報告**: DEBUG_FEEDBACK.md より
**優先度**: !! 重要
**原因**: 1枚目を選択した時点で、2枚目（ペアカード）のハイライト処理がなかった
**修正**:
- 1枚目選択後、ペアカードも即座にハイライト表示
**変更ファイル**:
- `scripts/Main.gd`
  - `_on_ability9_second_selection`で`deck_display.set_card_highlighted(pair_card, true)`を追加

---

### FIX-012: 選択可能カードのハイライトが不十分

**報告**: DEBUG_FEEDBACK.md より
**優先度**: !! 重要
**原因**: `is_selectable`は枠線のみ黄色、背景は変化なしだった
**修正**:
- 選択可能なカード（`is_selectable = true`）は背景も明るく表示
- `is_highlighted`または`is_selectable`のどちらかがtrueなら背景をlighten
**変更ファイル**:
- `scripts/Card.gd`
  - `_draw()`で`is_highlighted or is_selectable`の条件で背景を明るく表示

---

### FIX-013: 能力9で1枚目選択後にペアカードがハイライトされない

**報告**: DEBUG_FEEDBACK.md より（対話形式で特定）
**優先度**: !! 重要
**原因**: `_on_card_selected`で`select_target`呼び出し後に`update_display`を実行していた。これによりカードが再生成され、`_on_ability9_second_selection`で設定したハイライト状態が消えていた。
**修正**:
- 能力が実行されて状態が`SELECTING_TARGET`から変わった場合のみ`update_display`を呼び出す
- 能力9で1枚目選択中はまだ`SELECTING_TARGET`状態なので`update_display`をスキップ
**変更ファイル**:
- `scripts/Main.gd`
  - `_on_card_selected`で状態チェックを追加し、`SELECTING_TARGET`中は`update_display`を呼ばない

---

### FIX-014: カード選択時のハイライトが背景まで変わる

**報告**: DEBUG_FEEDBACK.md より
**優先度**: !! 重要
**原因**: FIX-012で`is_selectable`時も背景を明るくするように変更したが、元のカードの色がわかりづらくなった
**修正**:
- 選択可能時は枠線のみ黄色く太くする（背景は変更しない）
- `is_highlighted`による背景変更も削除
**変更ファイル**:
- `scripts/Card.gd`
  - `_draw()`で背景色の変更を削除、枠線のみ変更

---

### FIX-015: カード移動時にアニメーションがない

**報告**: DEBUG_FEEDBACK.md より
**優先度**: !! 重要
**原因**: `update_display`でカードを毎回削除・再生成していたためアニメーションができなかった
**修正**:
- カードを削除せず、位置をTweenでアニメーション移動
- `card_nodes`をDictionary（card_number → Card）に変更して再利用
- アニメーション設定を`@export`で調整可能に
  - `animation_duration`: アニメーション時間（デフォルト0.3秒）
  - `animation_enabled`: アニメーション有効/無効
- アニメーション中はカードクリックを無視
- `animation_completed`シグナルを追加
**変更ファイル**:
- `scripts/DeckDisplay.gd`
  - 全面的に書き換え
  - `_create_all_cards()`: 初回のみカード生成
  - `_animate_cards_to_positions()`: Tweenでアニメーション移動
  - `_update_card_positions_immediately()`: アニメーションなしで即座に更新

---

### FIX-016: デバッグ用クリアボタンがない

**報告**: DEBUG_FEEDBACK.md より
**優先度**: ! 軽微
**原因**: クリア画面のテストに実際にクリアする必要があり時間がかかる
**修正**:
- `debug_mode`フラグを追加（`@export`で切り替え可能）
- デバッグUI用のコンテナ`DebugContainer`を追加
- 「即クリア」ボタンを追加（デバッグモード時のみ表示）
- 今後のデバッグUI追加も`debug_mode`で一括管理可能
**変更ファイル**:
- `scripts/Main.gd`
  - `debug_mode`フラグを追加
  - `_setup_debug_ui()`関数を追加
  - `_on_debug_clear_button_pressed()`ハンドラを追加
- `scenes/Main.tscn`
  - `DebugContainer`ノードを追加
  - `DebugLabel`（[DEBUG MODE]表示）を追加
  - `DebugClearButton`（即クリアボタン）を追加

---

### FIX-017: クリア後の再開ができない

**報告**: DEBUG_FEEDBACK.md より
**優先度**: !!! 致命的
**原因**:
1. クリア画面表示時に`DeckDisplay`が表示されたままだった
2. `Card._input()`で`get_viewport().set_input_as_handled()`を呼んでいたため、カードがクリックイベントを消費
3. クリア画面のボタン位置とカード位置が重なり、ボタンにクリックが届かなかった
4. `_input()`は`visible = false`でも呼ばれる

**修正**:
- クリア画面表示時に`deck_display.visible = false`を設定
- `Card._input()`の先頭で`is_visible_in_tree()`チェックを追加
- 背景ColorRectに`mouse_filter = 2`（IGNORE）を設定

**変更ファイル**:
- `scripts/Main.gd`
  - `_show_clear_screen()`で`deck_display.visible = false`を追加
- `scripts/Card.gd`
  - `_input()`の先頭で`if not is_visible_in_tree(): return`を追加
- `scenes/Main.tscn`
  - `ClearBG`と`ClearScreen`に`mouse_filter = 2`を追加

---

### FIX-018: GitHub ActionsでWebエクスポートが失敗

**報告**: GitHub Actions実行エラー
**優先度**: !!! 致命的
**原因**:
1. `icon.svg`ファイルが存在しなかった
2. `export_presets.cfg`の`export_path`が空だった
3. `use_preset_export_path`が無効で、エクスポート先とデプロイ元が不一致

**修正**:
- `icon.svg`を追加（シンプルなゲームアイコン）
- `export_path="build/Web/index.html"`を設定
- GitHub Actionsワークフローで`use_preset_export_path: true`を有効化
- GitHub Pagesを`gh-pages`ブランチで有効化

**変更ファイル**:
- `icon.svg`（新規作成）
- `export_presets.cfg`
- `.github/workflows/export.yml`

---

### FIX-019: 日本語テキストが文字化け

**報告**: スマートフォンでの動作確認時
**優先度**: !!! 致命的
**原因**: 日本語フォントがプロジェクトに含まれていなかった。Godotのデフォルトフォントは日本語非対応。

**修正**:
- Noto Sans JP（Google Fonts）をダウンロードして追加
- `default_theme.tres`でフォントを設定
- CI環境でのタイミング問題を回避するため、`Main.gd`でテーマをコードから適用

**変更ファイル**:
- `assets/fonts/NotoSansJP-Regular.otf`（新規追加）
- `assets/fonts/NotoSansJP-Regular.otf.import`
- `assets/default_theme.tres`（新規作成）
- `scripts/Main.gd`

---

### FIX-020: スマホ画面で表示が崩れる

**報告**: スマートフォンでの動作確認時
**優先度**: !! 重要
**原因**:
1. 固定サイズ（800x600）でレイアウトしていた
2. ストレッチモードが未設定でアスペクト比が崩れた
3. カードとUIの位置が固定値だった

**修正**:
- `project.godot`にストレッチ設定を追加
  - `stretch/mode="canvas_items"`
  - `stretch/aspect="expand"`
- `DeckDisplay`が画面サイズに応じて中央に配置されるよう修正
- `Background`が画面全体を覆うよう動的にサイズ調整

**変更ファイル**:
- `project.godot`
- `scripts/DeckDisplay.gd`
- `scripts/Main.gd`
- `scenes/Main.tscn`

---

### FIX-021: クリア後のボタン操作・カード表示問題

**報告**: DEBUG_FEEDBACK.md より
**優先度**: !!! 致命的
**原因**:
1. デバッグクリアボタンがGameManagerの状態を正しく更新していなかった
2. クリア画面でカードが非表示になり、クリア状態を確認できなかった
3. カードが選択不可でも`_input`でイベントを消費し、ボタンクリックをブロックしていた

**修正**:
- `Card._input()`で`is_selectable = false`の場合は入力処理をスキップし、他のUI要素へ伝播させる
- クリア画面で`deck_display.visible = true`にしてカードを表示
- `deck_display.set_all_selectable(false)`でカードのクリックは無効化
- デバッグクリアボタンで山札をソート済み状態にし、`check_win()`で正しく勝利判定を発動

**変更ファイル**:
- `scripts/Card.gd`
  - `_input()`の先頭で`if not is_selectable: return`を追加
- `scripts/Main.gd`
  - `_show_clear_screen()`で`deck_display.visible = true`に変更
  - `_show_clear_screen()`で`set_all_selectable(false)`と`clear_highlights()`を追加
  - `_on_debug_clear_button_pressed()`で山札を`[1,2,3,4,5,6,7,8,9]`に設定し`check_win()`を呼び出す

---

### FIX-022: 能力3（中央送り）の挿入位置が間違っている

**報告**: DEBUG_FEEDBACK.md より
**優先度**: !!! 致命的
**原因**: `ability_top_to_middle()`で`MIDDLE_INDEX_8CARDS + 1`（index 4）に挿入していたため、期待より1つ下に移動していた

**修正**:
- `MIDDLE_INDEX_8CARDS`（index 3）に直接挿入するよう変更
- 期待動作: `[A,B,C,D,E,F,G,H]` → `[B,C,D,A,E,F,G,H]`（Aが4番目に移動）

**変更ファイル**:
- `scripts/Deck.gd`
  - `cards.insert(MIDDLE_INDEX_8CARDS + 1, top_card)` → `cards.insert(MIDDLE_INDEX_8CARDS, top_card)`

---

## 📱 次のステップ: スマートフォン実機検証

以下の項目を実機で検証する:

1. **タッチ操作**
   - カードのタップが正しく認識されるか
   - ボタンのタップが正しく動作するか
   - 誤タップ防止（カード間隔は十分か）

2. **表示確認**
   - 各画面サイズでの表示崩れがないか
   - テキストが読みやすいサイズか
   - カードの数字が見やすいか

3. **パフォーマンス**
   - アニメーションがスムーズか
   - 読み込み時間は許容範囲か

4. **ゲームプレイ**
   - 全能力が正しく動作するか
   - クリア判定が正しいか
   - ゲームの流れに違和感がないか

---
