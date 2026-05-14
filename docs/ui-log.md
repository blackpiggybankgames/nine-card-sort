
## 2026-05-11: カード選択UI改修（隣接拡張方式）

### 変更内容
複数カード選択が必要な能力（カード2・6・9）の選択UIを、代表カード1枚選択から全カードを逐次選択する「隣接拡張方式」に変更。

**変更した能力:**
- カード2（3枚順繰り）: 1クリック → 3クリック（1枚目自由選択、以降は隣接のみ）
- カード6（2セット下送り）: 2クリック → 4クリック（ペア1を隣接拡張、ペア2を別途隣接拡張）
- カード9（4枚逆順）: 1クリック → 4クリック（1枚目自由選択、以降は隣接のみ）

**技術的変更:**
- `GameManager`: シグナルを `target_selection_step_updated(card, step, selected_so_far)` に統一、`_required_target_count()` 追加
- `Deck.ability_reverse_four()`: 引数を `pair_top_card` から `first_card`（4枚先頭）に変更
- `DeckDisplay`: `set_adjacent_extension_selectable()` / `set_card6_pair2_start_selectable()` / `set_card6_pair2_adjacent_selectable()` 追加
- `Main.gd`: 統一ハンドラ `_on_target_selection_step_updated()` 追加、カード9アニメーション更新

## 2026-04-07: 能力発動アニメーションのステップ分割

### 変更内容
能力発動時に処理ステップを分けてアニメーション表示するよう改修。

**追加機能:**
- 各処理ステップの間に0.3秒のポーズを挿入
- アニメーション中に処理内容を自然言語でラベル表示（StepLabel）

**アニメーション流れ（新）:**
1. 「【能力名】」表示（0.5秒）
2. 能力ステップ（カード移動アニメーション＋説明ラベル）
3. 「発動カードを一番下へ移動」アニメーション
4. 次の手番

**2ステップに分割したカード:**
- カード4（どかす）: 両隣入れ替え → 選択カード一番下
- カード6（2セット下送り）: 1組目送り → 2組目送り

**変更ファイル:**
- `scenes/Main.tscn`: StepLabel / StepLabelBG ノード追加
- `scripts/GameManager.gd`: `ability_ready` シグナル追加、`commit_ability_execution()` に改名
- `scripts/Main.gd`: `_on_ability_ready()` コルーチン・`_compute_animation_steps()` 追加

## 2026-04-08: カード移動アニメーションをコの字（U字）に変更

**対象:** `scripts/DeckDisplay.gd`

**変更内容:**
- `_animate_cards_to_positions` を `old_deck` を受け取るように変更
- 大きく移動するカード（位置変化 > 1）が1枚だけの場合、コの字アニメーションを適用
- コの字: フェーズ1（上昇）→ フェーズ2（水平移動）→ フェーズ3（降下＋隙間詰め）
- 複数枚が大移動する場合（全体リバース、上下入れ替えなど）は従来の並列アニメーション継続

**追加パラメータ（@export）:**
- `fly_height = -200.0`
- `fly_up_duration = 0.15`
- `fly_horizontal_duration = 0.2`
- `fly_down_duration = 0.15`

**コの字が適用される主なケース:** スキップ、カード2（3枚順繰り）、カード4ステップ2（どかす）、カード8裏面（任意移動）、発動カード→一番下

## 2026-04-14: 発動カード移動アニメーション — 底面パス追加

**変更内容:**
- `DeckDisplay.gd` の `_animate_u_shape` に底面パスを追加
- 発動カードが分離表示中（`position.y > active_card_offset_y * 0.5` = 60px超）の場合、山札の下側を通る逆コの字アニメーションを使用
- 新規 export 変数: `fly_depth = 250.0`（底面パス時の最下点Y座標）

**変更理由:**
発動カードはすでに山札の下側に分離表示されているため、上側を経由するアニメーションは冗長で違和感があった。

## 2026-04-14: 発動カード移動アニメーション — 一直線化

**変更内容:**
- `DeckDisplay.gd` に `update_display_simple()` を追加（コの字なし・`_animate_cards_simple` 固定）
- `Main.gd` の発動カード一番下移動ステップで `update_display` → `update_display_simple` に変更

**変更理由:**
スキップ時と能力発動時の発動カード移動軌道を統一。どちらも一直線で山札の一番下へ移動するようにした。

## 2026-04-14: クリア演出強化

### 変更内容
- クリア時にズームイン＋ヒットストップ演出を追加
- クリア画面表示後、バックグラウンドで山札を1始まりにゆっくりソート

### 演出フロー
1. 最後に底へ移動したカードにズームイン（2x、0.35秒、EASE_OUT）
2. ヒットストップ（静止 0.5秒）
3. クリア画面表示
4. DeckDisplay を元位置・スケールに復元（0.7秒）
5. 1が先頭になるまで1枚ずつローテーション（0.2秒間隔 + 0.5秒アニメ）

### 変更ファイル
- `scripts/DeckDisplay.gd`: `update_display_with_duration()` 追加
- `scripts/Main.gd`: `_play_clear_sequence()` / `_play_clear_hit_stop()` / `_play_clear_sort_animation()` 追加
- `scenes/Main.tscn`: ClearBG alpha 0.9→0.75（デッキが透けて見えるように）

## 2026-04-14: クリア演出修正（ズームタイミング改善）

### 変更内容
- クリア時のズームを「事後ズーム」から「最後のカード移動と同時ズーム」に変更
- 能力カードが底に移動する直前でヒットストップ（0.5秒静止）
- その後、DeckDisplayをズームインしながら能力カードがゆっくり（0.8秒）底位置へ移動
- `_will_win(final_deck)` で先読み勝利判定を実装

### 演出フロー（新）
1. ステップアニメーション完了
2. 「発動カードを一番下へ移動」ラベル表示 → 0.5秒ヒットストップ
3. ラベル非表示 → ズームイン+カード移動（同時、0.8秒）
4. `_clear_zoom_done = true` を立てる → `commit_ability_execution`
5. `_play_clear_sequence` がズーム済みフラグを確認、`_play_clear_hit_stop` をスキップ
6. クリア画面表示 → バックグラウンドソート

### 変更ファイル
- `scripts/Main.gd`: `_clear_zoom_done`フラグ、`_will_win()`、`_animate_winning_card_to_bottom()` 追加

## 2026-04-14: クリア演出修正（ズームターゲット変更）

### 変更内容
- ズームターゲットを「能力カードの底移動先」から「エフェクトで最も大きく動いたカード」に変更
- 演出フロー: ステップ完了 → キーカードにズームイン+ヒットストップ → ズームアウトしながら能力カードを底へ

### キーカード特定ロジック
- `_find_zoom_target_card()`: エフェクト前後のデッキを比較し、インデックス移動量が最大のカードを返す
- ステップなし（カード8表面など）はデッキ先頭カード

### 変更ファイル
- `scripts/Main.gd`: `_animate_winning_card_to_bottom` を削除し、`_find_zoom_target_card()`・`_zoom_into_key_card()`・`_move_ability_card_with_zoom_restore()` の3関数に置き換え

## 2026-04-16: 挿入位置選択UIを矢印方式に変更

### 変更内容
カードとカードの間に挿入位置を選ぶ操作を、カードクリック方式から矢印クリック方式に変更。

**対象カード:**
- カード7「3枚ブロック差し込み」ステップ1: 差し込み先ギャップを矢印で選択
- カード8「任意移動」ステップ2: 挿入位置を矢印で選択

**変更内容:**
- `InsertionArrow.gd`（新規）: クリック可能な下向き三角矢印ノード
- `DeckDisplay.gd`: `show_insertion_arrows()` / `hide_insertion_arrows()` / `insertion_point_selected` シグナルを追加
- `Main.gd`: カード7ステップ1・カード8ステップ2で矢印UIを使用、`_on_insertion_point_selected()` 追加

**矢印の位置:**
カードファンの上方（y=−100）にカード間隔の中点で配置。下向き三角形（▼）。

---

## 2026-05-01 — ビジュアルリニューアル Day2：ボタンアセット適用

**変更ファイル:**
- `assets/default_theme.tres`: primary ボタン用 StyleBoxTexture（normal/hover/pressed/focus）+ Button フォントカラー 4種を登録
- `scenes/Main.tscn`: secondary ボタン用 StyleBoxTexture 追加、全ボタンに `CanvasItemMaterial` Add ブレンド適用

**適用ボタン一覧:**

| ボタン | スタイル | ファイル |
|--------|---------|---------|
| StartButton | primary（theme継承） | btn_primary_*.png |
| DailyChallengeButton | primary（theme継承） | btn_primary_*.png |
| UseAbilityButton | primary（theme継承） | btn_primary_*.png |
| ShareButton | primary（theme継承） | btn_primary_*.png |
| RetryButton | primary（theme継承） | btn_primary_*.png |
| SkipButton | secondary（per-node override） | btn_secondary_*.png |
| CancelButton | secondary（per-node override） | btn_secondary_*.png |
| TitleButton | secondary（per-node override） | btn_secondary_*.png |

**Add ブレンド:** 全ボタンに `CanvasItemMaterial_add`（blend_mode=1）を適用。ボタン画像の黒背景を加算合成で透過。

**NinePatch マージン:** primary: left/right=24, top/bottom=18 / secondary: left/right=20, top/bottom=16

## 2026-05-04 — クリア画面の再構成（result_board.png ベース）

**変更ファイル:** `scenes/Main.tscn`, `scripts/Main.gd`

**内容:**
- クリア画面を result_board.png（800×1192、真鍮フレーム＋羊皮紙）中心のレイアウトに再構成
- result_board.png（幅330px / α=0.85）を中央配置。背後のゲームカードが透けて見える
- ボードヘッダーの数字ボックス上に最終手数を BoardMovesLabel で動的表示
- 羊皮紙エリア内の StatsContainer にスキップ回数＋能力9行をセピア色（#593814）14ptで表示
- ボタン3つ（シェア・もう一度・タイトルへ）を横並びに配置、すべて真鍮スタイル（primary）に統一
- 削除: OrnamentTop/Bottom, ClearLabel, TurnCountLabel, SkipCountLabel, DividerTop/Bottom

## 2026-05-04 — アンティーク・カジノスタイルへの統一

**変更ファイル:** `scripts/Card.gd`, `assets/default_theme.tres`, `scenes/Main.tscn`, `assets/fonts/`

**内容:**
- カード識別色をパステル→アースカラー（バーガンディ・アンバー・マスタード等）に変更。透過度 0.35→0.25、枠線をダークブラウン/アンティークゴールドに変更
- フォントを NotoSansJP（ゴシック）→ NotoSerifJP（明朝体・可変フォント）に変更
- HUDヘッダーを panel_hud.png → StyleBoxFlat（ダークブラウン #33241a + ゴールドボーダー）に変更
- HUDラベルにアンティーククリーム色 (#f2e0b7)、InstructionLabel・StepLabel にアンティークゴールドを適用

## 2026-05-11: ボタン文字の白つぶれ修正

**対象**: 全画面のボタン（タイトル・ゲーム・クリア画面）

**問題**:
- ボタン文字が白くつぶれて読めなかった

**原因**:
1. 輝度ベースの透過 (`smoothstep(0.05, 0.25, lum)`) がボタン本体（暗い茶色）も半透明にしていた
2. `COLOR = col` がフォントカラー（頂点カラー）を消し、テキストが白く表示されていた

**修正内容** (`assets/shaders/black_transparent.gdshader`):
- 輝度 → `max(r,g,b)` に変更：純粋な黒のみ透過、暗い茶色は不透過
- `min(col.a, ...)` でフォントアトラスのアルファ形状を保持
- `COLOR = col * COLOR` でフォントカラーを保持

## 2026-05-11: ボタン disabled 状態の表示修正・フォントを太字化

**対象**: 全画面のボタン（`assets/default_theme.tres`）

**問題1**: キャンセルボタン表示中（能力選択モード）に能力を使用ボタンのラベルが読めない
- 原因: `Button/styles/disabled` が未定義 → Godot デフォルトのフラット灰色スタイルになりボタン画像が消えていた
- 修正: `StyleBoxTexture_primary_disabled` を追加（btn_primary_normal.png を dimmed で表示）
- 合わせて `font_disabled_color` を `Color(0.62, 0.50, 0.30, 0.85)` に変更（視認性向上）

**問題2**: 全ボタンの文字が細く読みづらい
- 原因: `Button/fonts/font` 未設定のため NotoSerifJP がデフォルト wght:400 で表示されていた
- 修正: `FontVariation_btn` (wght:700) を追加し `Button/fonts/font` に設定

## 2026-05-11: ボタンフォントを ShipporiMincho-ExtraBold に変更

**対象**: 全画面のボタン8個（Main.tscn）

**変更内容**:
- ボタンフォントを NotoSerifJP wght:700 → ShipporiMincho-ExtraBold.ttf に変更
- Main.tscn に ext_resource として追加（id: 19_shippori）
- `theme_override_fonts/font = ExtResource("19_shippori")` を8ボタン全てに設定
- BoardMovesLabel・MovesCountLabel は従来どおり FontVariation_moves_bold を維持

## 2026-05-11 カード選択エフェクトのクリア修正

- **対象**: ゲーム画面 / カード選択式能力発動時
- **変更**: `_on_ability_ready` 冒頭で `set_all_selectable(false)` と `clear_highlights()` を呼ぶよう修正
- **変更ファイル**: `scripts/Main.gd`
- **理由**: カード選択完了 → 能力発動前のタイミングで選択可能エフェクト（ホワイトゴールドグロー・スケール拡大）が残り続けていた

## 2026-05-14: シェアパネルボタンを TextureButton + Label 方式に変更

**対象**: シェアパネル内の金色ボタン3つ（テキストをコピー・画像を保存・アンケートに答える）

**問題**:
1. ボタンが全体的に黒く見える（金色が出ない）
2. マウスホバー時に視覚的な反応がない
3. ボタン押下後にテキストが白くなる

**原因**:
- 旧方式（`TextureRect`+シェーダー + `Button`/StyleBoxEmpty 重ね）では:
  - `Button` のホバー/プレス状態が `TextureRect` に伝わらない
  - `Button` にシェーダーを当てると頂点カラー（フォント色）と干渉してテキストが白くなる

**修正内容** (`scripts/Main.gd`):
- `_make_gold_button` を `TextureButton`（テクスチャ切り替え）+ `Label`（シェーダーなし）方式に変更
- texture_normal / focused: `gold_button_blank.png`
- texture_hover: `btn_primary_hover.png`（明るいゴールド）
- texture_pressed: `btn_primary_pressed.png`（暗めゴールド）
- `Label` を別ノードとして配置し `mouse_filter = IGNORE`、ShipporiMincho-ExtraBold / ダークブラウンで描画

## 2026-05-14: シェアパネルボタン画像をタイトル画面と統一・クリック後ホバー修正

**対象**: シェアパネル内の金色ボタン3つ

**問題**:
1. クリック後にマウスを重ねても反応しない
2. `gold_button_blank.png`（normal）と `btn_primary_hover.png`（hover）の見た目のギャップが大きい

**原因**:
- `TextureButton` はクリック後にフォーカスを取得し、`texture_focused` が表示されてホバー状態が上書きされていた

**修正内容** (`scripts/Main.gd`):
- `texture_normal` を `gold_button_blank.png` → `btn_primary_normal.png` に変更（タイトル画面と統一）
- `texture_focused` を削除
- `focus_mode = Control.FOCUS_NONE` を追加（クリック後もホバーが正常動作）

## 2026-05-14: シェアパネルToastメッセージの位置を修正

**対象**: シェアパネルの操作完了メッセージ（Toast）

**問題**: Toastの位置がパネル下部（y=454）にあり見えなかった

**修正**: `_panel_toast.position.y` を `board_h - 46.0`（454）→ `130.0` に変更
（SHAREタイトル下・最初のボタン上のエリアに移動）

**変更ファイル**: `scripts/Main.gd`
