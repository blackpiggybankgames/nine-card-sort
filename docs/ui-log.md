
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
