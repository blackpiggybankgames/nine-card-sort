# ビジュアルリニューアル 3日間実装計画

## 概要

Nine Card Sort のUIを、現在のコードベースのStyleBoxFlatからGemini生成画像アセットに置き換える。
全17アセットを3日間に分けて生成・実装する。

**プロンプト定義:** `docs/temp/gemini_asset_prompts.md`  
**Godotプロジェクトルート:** `/home/dai/games/nine-card-sort/`

---

## アセット保存先ルール

Geminiで生成した画像は以下のディレクトリに保存する。
Godot外（Windowsエクスプローラー等）から配置する場合は WSL パスを使用する。

| カテゴリ | Windowsパス（WSL経由） | Godot内パス |
|---------|----------------------|------------|
| 背景 | `\\wsl.localhost\Ubuntu\home\dai\games\nine-card-sort\assets\images\bg\` | `res://assets/images/bg/` |
| ボタン | `\\wsl.localhost\Ubuntu\home\dai\games\nine-card-sort\assets\images\buttons\` | `res://assets/images/buttons/` |
| パネル | `\\wsl.localhost\Ubuntu\home\dai\games\nine-card-sort\assets\images\panels\` | `res://assets/images/panels/` |
| カード | `\\wsl.localhost\Ubuntu\home\dai\games\nine-card-sort\assets\images\cards\` | `res://assets/images/cards/` |
| UI装飾 | `\\wsl.localhost\Ubuntu\home\dai\games\nine-card-sort\assets\images\ui\` | `res://assets/images/ui/` |
| タイトル | `\\wsl.localhost\Ubuntu\home\dai\games\nine-card-sort\assets\images\title\` | `res://assets/images/title/` |
| リザルト | `\\wsl.localhost\Ubuntu\home\dai\games\nine-card-sort\assets\images\result\` | `res://assets/images/result/` |

**ディレクトリはGodotが自動生成しない。** 画像配置前にフォルダを手動で作成すること。

---

## Day 1 — 基盤・カード・背景アセット（5枚）

### 目的
ゲーム画面の土台となる背景・カード・パネルを実装し、
ゲーム画面全体のベースビジュアルを確立する。

### 1. 人間の作業（Gemini画像生成）

`docs/temp/gemini_asset_prompts.md` の以下セクションを使って1枚ずつ生成する。

| # | プロンプトセクション | 保存ファイル名 | 保存先フォルダ |
|---|------------------|--------------|--------------|
| 1 | §1 bg_velvet_green | `bg_velvet_green.png` | `assets/images/bg/` |
| 2 | §10 card_face | `card_paper_texture.png` | `assets/images/cards/` |
| 3 | §8 panel_hud | `panel_hud.png` | `assets/images/panels/` |
| 4 | §9 panel_ability_list | `panel_ability_list.png` | `assets/images/panels/` |
| 5 | §13 divider_gold | `divider_gold.png` | `assets/images/ui/` |

生成後、上記フォルダを作成して配置する。

### 2. AIの作業（Godot実装）

#### 2-1. bg_velvet_green.png — ゲーム背景

**対象ノード:** `Main.tscn > Background`（ColorRect）  
**変更内容:** ColorRect を TextureRect に変更し、タイル表示を設定する。

```
変更前: [node name="Background" type="ColorRect"]
変更後: [node name="Background" type="TextureRect"]
  texture = preload("res://assets/images/bg/bg_velvet_green.png")
  stretch_mode = TextureRect.STRETCH_TILE
  anchors_preset = 15（全画面）
```

#### 2-2. card_paper_texture.png — カード表面

**対象スクリプト:** `scripts/Card.gd`  
**実装済み:** `_draw()` 内で `draw_texture_rect` を使用して `card_paper_texture.png` を描画済み。

#### 2-3. panel_hud.png — 上部HUDパネル

**対象ノード:** `Main.tscn > UILayer/GameUI/TopPanel`（Panel）  
**変更内容:** StyleBoxFlat を StyleBoxTexture（NinePatch設定）に置き換える。

Godotエディタでの操作手順:
1. `assets/images/panels/panel_hud.png` をインポート
2. `assets/themes/` フォルダを作成し、`StyleBoxTexture` リソースを新規作成
3. NinePatchマージン: left=16, right=16, top=16, bottom=16
4. TopPanel の theme_override_styles/panel にこのStyleBoxTextureをセット

#### 2-4. panel_ability_list.png — 能力一覧パネル

**現状:** 能力一覧パネルは現時点でシーンに存在しない（将来実装）。  
**Day 1での対応:** アセットをフォルダに配置するのみ。実装は後日のUI変更タスクで行う。  
**保存先:** `assets/images/panels/panel_ability_list.png`

#### 2-5. divider_gold.png — 区切り線

**対象画面:** クリア画面（ClearScreen）とタイトル画面  
**変更内容:** 区切りが必要な箇所にTextureRectノードを追加。

クリア画面では以下の位置に追加:
- `ClearLabel`（クリア！）の下
- `StatsContainer` の下（シェアボタンの上）

```
[node name="DividerTop" type="TextureRect" parent="UILayer/ClearScreen"]
  texture = preload("res://assets/images/ui/divider_gold.png")
  anchors_preset = 5（水平中央）
  offset_top = 148.0  # ClearLabelの下
```

### Day 1 完了条件
- [ ] ゲーム画面の背景がベルベットグリーンになっている
- [ ] カードにアイボリーの質感がある
- [ ] 上部HUDパネルに半透明ダークパネル背景が表示されている
- [ ] クリア画面に金の区切り線が入っている

---

## Day 2 — ボタンアセット（6枚）

### 目的
全ボタンを真鍮/銅のNinePatchボタンに統一する。
Godotのテーマシステムを使い、シーンファイルを最小限の変更で全ボタンを一括更新する。

### 1. 人間の作業（Gemini画像生成）

| # | プロンプトセクション | 保存ファイル名 | 保存先フォルダ |
|---|------------------|--------------|--------------|
| 1 | §2 btn_primary_normal | `btn_primary_normal.png` | `assets/images/buttons/` |
| 2 | §3 btn_primary_hover | `btn_primary_hover.png` | `assets/images/buttons/` |
| 3 | §4 btn_primary_pressed | `btn_primary_pressed.png` | `assets/images/buttons/` |
| 4 | §5 btn_secondary_normal | `btn_secondary_normal.png` | `assets/images/buttons/` |
| 5 | §6 btn_secondary_hover（hover） | `btn_secondary_hover.png` | `assets/images/buttons/` |
| 6 | §6 btn_secondary_pressed（pressed） | `btn_secondary_pressed.png` | `assets/images/buttons/` |

### 2. AIの作業（Godot実装）

#### 2-1. StyleBoxTextureリソースを作成

`assets/themes/` フォルダに以下6つのリソースを作成する。

**btn_primary_normal.tres:**
```
[gd_resource type="StyleBoxTexture"]
texture = preload("res://assets/images/buttons/btn_primary_normal.png")
texture_margin_left = 24
texture_margin_right = 24
texture_margin_top = 18
texture_margin_bottom = 18
```

同様に `btn_primary_hover.tres`, `btn_primary_pressed.tres`,  
`btn_secondary_normal.tres`, `btn_secondary_hover.tres`, `btn_secondary_pressed.tres` を作成。
secondary は margin left/right=20, top/bottom=16。

#### 2-2. default_theme.tres を更新

`assets/default_theme.tres` にボタンスタイルを登録する。

```
# Primaryボタン（能力を使う・シェアする・もう一度）
Button/styles/normal    = btn_primary_normal.tres
Button/styles/hover     = btn_primary_hover.tres
Button/styles/pressed   = btn_primary_pressed.tres
Button/styles/focus     = btn_primary_hover.tres（フォーカス時はホバーと同じ）
```

**Secondaryボタンの扱い:**  
`default_theme.tres` はプライマリ基準にする。  
セカンダリ（スキップ・タイトルへ・キャンセル）は `theme_override_styles` で個別に設定する。

#### 2-3. 各ボタンノードの個別設定

`Main.tscn` で以下のノードにセカンダリスタイルを適用:

| ノード | スタイル |
|--------|---------|
| `UILayer/GameUI/SkipButton` | btn_secondary |
| `UILayer/GameUI/CancelButton` | btn_secondary |
| `UILayer/ClearScreen/TitleButton` | btn_secondary |

プライマリはテーマから自動適用されるため変更不要:
- `StartButton`, `DailyChallengeButton`（タイトル画面）
- `UseAbilityButton`（ゲーム画面）
- `ShareButton`, `RetryButton`（クリア画面）

#### 2-4. ボタンテキストカラー調整

NinePatchボタンのテキスト色を画像の色調に合わせる。
`default_theme.tres` に以下を追加:

```
Button/colors/font_color          = Color(0.98, 0.93, 0.78, 1)   # アンティークホワイト
Button/colors/font_hover_color    = Color(1.0, 1.0, 0.9, 1)
Button/colors/font_pressed_color  = Color(0.85, 0.75, 0.55, 1)
Button/colors/font_disabled_color = Color(0.5, 0.45, 0.35, 0.7)
```

### Day 2 完了条件
- [ ] 全ボタンが真鍮/銅の質感になっている
- [ ] ホバー・押下時に状態変化がある
- [ ] テキストが読みやすいカラーになっている
- [ ] StyleBoxFlatの青ボタンが残っていない

---

## Day 3 — タイトル・クリア・リザルトアセット（6枚）

### 目的
タイトル画面・クリア画面の装飾を完成させ、リザルトカード（シェア画像）を新アセットで刷新する。

### 1. 人間の作業（Gemini画像生成）

| # | プロンプトセクション | 保存ファイル名 | 保存先フォルダ |
|---|------------------|--------------|--------------|
| 1 | §7 logo_title | `logo_title.png` | `assets/images/title/` |
| 2 | §11 clear_ornament_top | `clear_ornament_top.png` | `assets/images/ui/` |
| 3 | §12 clear_ornament_bottom | `clear_ornament_bottom.png` | `assets/images/ui/` |
| 4 | §14 result_card_bg | `result_card_bg.png` | `assets/images/result/` |
| 5 | §15 result_card_line_premium | `result_card_line_premium.png` | `assets/images/result/` |
| 6 | §16 result_card_seal | `result_card_seal.png` | `assets/images/result/` |

### 2. AIの作業（Godot実装）

#### 2-1. logo_title.png — タイトル装飾フレーム

**対象ノード:** `Main.tscn > UILayer/TitleScreen`  
**変更内容:** `TitleLabel`・`SubtitleLabel` の後ろに装飾フレームを追加。

```
[node name="LogoFrame" type="TextureRect" parent="UILayer/TitleScreen"]
  texture = preload("res://assets/images/title/logo_title.png")
  anchors_preset = 5（水平中央）
  offset_left = -240.0
  offset_top = 100.0
  offset_right = 240.0
  offset_bottom = 260.0
  # TitleLabel / SubtitleLabel より z_index を低くすること
```

`TitleBG`（ColorRect）は削除してよい。タイトル画面の背景はメインの `Background`（bg_velvet_green）で代替する。

#### 2-2. clear_ornament_top/bottom.png — クリア画面装飾

**対象ノード:** `Main.tscn > UILayer/ClearScreen`  
**変更内容:** 上部・下部に装飾TextureRectを追加する。

```
[node name="OrnamentTop" type="TextureRect" parent="UILayer/ClearScreen"]
  texture = preload("res://assets/images/ui/clear_ornament_top.png")
  anchors_preset = 5（水平中央）
  offset_top = 30.0

[node name="OrnamentBottom" type="TextureRect" parent="UILayer/ClearScreen"]
  texture = preload("res://assets/images/ui/clear_ornament_bottom.png")
  anchors_preset = 5（水平中央）
  offset_top = 600.0  # TitleButton の下
```

`ClearBG`（ColorRect）は透過度を下げるか削除してビジュアルを確認すること。

#### 2-3. リザルトカード画像の更新（重要：実装上の注意あり）

**現状の実装:** リザルトカードは JavaScript の Canvas 2D API で生成している（`scripts/Main.gd > _build_result_card_js()`）。  
**Godot SubViewportは使用していない。**

そのため、`result_card_bg.png`, `result_card_line_premium.png`, `result_card_seal.png` を  
**JavaScriptから画像として読み込む形で実装する。**

##### 実装方針

Godot Web Export後のサーバー上で画像はスタティックファイルとして公開される。
JSコード内で `Image` オブジェクトとして非同期ロードし、Canvas に描画する。

**`scripts/Main.gd > _build_result_card_js()` の変更方針:**

```javascript
// 変更前: ctx.fillRect で背景を塗りつぶしていた箇所
// 変更後: Image オブジェクトで result_card_bg.png を描画

var bgImg = new Image();
bgImg.onload = function() {
  ctx.drawImage(bgImg, 0, 0, W, H);  // 背景描画
  // テキスト・シール等を上に重ねる処理を続ける
};
bgImg.src = '/nine-card-sort/assets/images/result/result_card_bg.png';
```

**画像パス:** GitHub Pages の公開パスに合わせる。  
現在の公開URL（`Config.get_share_url()` 参照）から逆算して設定すること。

**画像ロードの非同期処理:** `Image.onload` コールバック内でCanvas描画を完結させ、
完了後に `canvas.toBlob()` → ダウンロード処理を行う。
既存のJSコードはシンプルな同期処理なので、Promiseまたはコールバックチェーンに書き直す必要がある。

##### 具体的な変更ファイル

- `scripts/Main.gd` — `_build_result_card_js()` 関数を全面改修
- 改修後のJSは画像3枚（bg, line_premium, seal）をロードしてからCanvas描画を開始する

### Day 3 完了条件
- [ ] タイトル画面に金のロゴフレームが表示されている
- [ ] クリア画面の上下に金の装飾が表示されている
- [ ] シェアボタンを押すと新デザインのリザルトカードがダウンロードされる
- [ ] リザルトカードに羊皮紙背景・豪華な区切り線・金の印章が使われている

---

## 既知の課題

| # | 優先度 | 内容 | 発生箇所 |
|---|--------|------|---------|
| 1 | 低 | bg_velvet_green.png のタイル境界線が目立つ。シームレス感が不足している。画像の再生成（より境界が目立たないテクスチャ）またはGodot側でのブレンド処理を検討。 | Background (TextureRect) |
| 2 | 低 | divider_gold.png の区切り線がゲーム全体と調和していない。Add blendで黒は透過されているが、金の線の見た目が浮いている。画像の再生成（より透過に適したデザイン）またはブレンドモード・カラーモジュレート調整を検討。 | ClearScreen (DividerTop / DividerBottom) |

---

## 全体の実装順序と依存関係

```
Day 1: 背景・カード・パネル
  └─ ゲーム画面の基本ビジュアルが成立する

Day 2: ボタン（Day 1 完了後に実施）
  └─ Day 1 の背景と組み合わせてゲーム画面が完成する

Day 3: タイトル・クリア・リザルト（Day 2 完了後に実施）
  └─ 全画面のビジュアルが完成する
```

Day 2 以降は前日の成果物に依存しないため、  
画像が揃い次第 AI に実装を依頼してよい。

---

## 作業完了後の後処理

- `docs/temp/gemini_asset_prompts.md` の内容を `docs/SYSTEM_SPEC.md` のUI要素テーブルに統合する
- `docs/temp/visual_renewal_plan.md`（本ファイル）を削除する
- `docs/temp/` 内の一時ファイルを整理する

---

## AIへの指示の出し方

各日の実装を依頼する際は `/change-ui` スキルを使う。

```
/change-ui visual_renewal_plan.md
```

または具体的に:

```
visual_renewal_plan.md の Day 1 の実装をお願いします。
画像は assets/images/ 以下に配置済みです。
```
