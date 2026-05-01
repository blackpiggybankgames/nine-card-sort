# Gemini 画像生成指示書 — Nine Card Sort ビジュアルリニューアル

## 共通スタイルガイド（全プロンプトに適用）

全アセットで以下の世界観を統一すること。

| 要素 | 仕様 |
|------|------|
| スタイル | Classic casino / Antique parlor. Rich and dignified, NOT cartoonish |
| 背景素材 | Dark forest green velvet fabric |
| 装飾・文字 | Antique gold (#C9A84C), worn and lustrous |
| ボタン土台 | Burnished brass / aged copper metallic |
| カード | Ivory parchment, aged paper, cream (#F5E6C8) |
| テクスチャ感 | Flat-ish but with subtle material depth — no 3D realism, no pixel art |
| 禁止 | Neon colors, modern flat design, photorealism, cartoon, anime |
| **背景処理** | **透過エリアはアルファ透過ではなく、純粋な黒 (#000000) で塗りつぶすこと。GodotのCanvasItemMaterial Blend Mode: Add（加算合成）により黒が透過される前提。** ただし bg_velvet_green.png（タイル背景）と result_card_bg.png（シェア用不透明背景）はこのルールの例外。 |

---

## アセット一覧

| ファイル名 | 役割 | Godotノード | サイズ (px) | NinePatchマージン |
|------------|------|-------------|-------------|-------------------|
| bg_velvet_green.png | 全画面背景テクスチャ（タイル可） | TextureRect | 512×512 | なし |
| btn_primary_normal.png | メインボタン 通常状態 | NinePatchRect | 240×60 | 左右:24 上下:18 |
| btn_primary_hover.png | メインボタン ホバー状態 | NinePatchRect | 240×60 | 同上 |
| btn_primary_pressed.png | メインボタン 押下状態 | NinePatchRect | 240×60 | 同上 |
| btn_secondary_normal.png | サブボタン 通常状態（スキップ・タイトルへ等） | NinePatchRect | 200×52 | 左右:20 上下:16 |
| btn_secondary_hover.png | サブボタン ホバー状態 | NinePatchRect | 200×52 | 同上 |
| btn_secondary_pressed.png | サブボタン 押下状態 | NinePatchRect | 200×52 | 同上 |
| logo_title.png | タイトルロゴ（テキストなし、装飾フレームのみ） | TextureRect | 480×160 | なし |
| panel_hud.png | 画面上部 HUDパネル背景 | NinePatchRect | 800×80 | 左右:16 上下:16 |
| panel_ability_list.png | 能力一覧パネル背景 | NinePatchRect | 320×400 | 左右:16 上下:16 |
| card_face.png | カード表面（数字はGodotのLabelで上書き） | TextureRect / Sprite2D | 100×148 | なし |
| clear_ornament_top.png | クリア画面 上部ゴールド装飾 | TextureRect | 480×80 | なし |
| clear_ornament_bottom.png | クリア画面 下部ゴールド装飾 | TextureRect | 480×80 | なし |
| divider_gold.png | ゴールド水平区切り線 | TextureRect | 400×12 | なし |
| result_card_bg.png | シェア用リザルトカード 羊皮紙背景 | TextureRect (SubViewport内) | 600×800 | なし |
| result_card_line_premium.png | リザルトカード専用 豪華な区切り線 | TextureRect (SubViewport内) | 500×24 | なし |
| result_card_seal.png | リザルトカード用 金のスタンプ/印章 | TextureRect (SubViewport内) | 96×96 | なし |

---

## 各アセットの Gemini 生成プロンプト

---

### 1. bg_velvet_green.png — 全画面背景テクスチャ

**仕様:** 512×512px、タイル状に繰り返せる seamless テクスチャ、透過なし

**プロンプト（英語）:**

```
A seamless tileable texture of dark forest green velvet fabric.
Rich, deep green color (#1A2E1A range). Subtle fabric weave visible.
No pattern, no decoration — pure material texture.
Flat lighting, no strong shadows or highlights.
Style: vintage casino table felt, luxurious and muted.
Image size: 512x512 pixels.
```

---

### 2. btn_primary_normal.png — メインボタン（通常）

**仕様:** 240×60px、黒背景PNG、NinePatch用に左右24px・上下18px が「端キャップ」、中央が伸縮する設計

**Godot NinePatch マージン:** left=24, right=24, top=18, bottom=18

**プロンプト（英語）:**

```
A horizontal button background image for a UI, 240x60 pixels.
Style: burnished brass / aged gold metallic plate.
Rounded corners (radius ~12px). Slight raised bevel effect — subtle emboss, not glossy.
Left and right ends (each ~24px wide) have distinct decorative end-cap styling (slightly curved inward, ornamental ridge).
The center section (192px wide) is plain metallic — designed to stretch in NinePatch.
Color: warm antique brass (#B5852A to #8C6420 gradient, darker at edges).
No text. No icons.
IMPORTANT: The background (all areas outside the button shape) must be solid pure black (#000000).
Do NOT use alpha transparency — use solid black for all non-button areas.
Output: PNG with solid black background, no drop shadow.
```

---

### 3. btn_primary_hover.png — メインボタン（ホバー）

**仕様:** 240×60px、通常より明るい

**プロンプト（英語）:**

```
Same as the brass button image (240x60px, NinePatch-ready with 24px end-caps),
but the metallic surface is brighter and more luminous — as if a warm light is shining on it.
Color: lighter antique gold (#D4A843 to #A87830), with a faint golden sheen highlight in the center.
No text.
IMPORTANT: The background (all areas outside the button shape) must be solid pure black (#000000).
Do NOT use alpha transparency — use solid black for all non-button areas.
```

---

### 4. btn_primary_pressed.png — メインボタン（押下）

**仕様:** 240×60px、通常より暗く凹んだ印象

**プロンプト（英語）:**

```
Same brass button (240x60px, NinePatch-ready with 24px end-caps),
but the surface appears depressed / pressed inward — darker, with inverted bevel (inset shadow at top, highlight at bottom).
Color: darker brass (#7A5518 to #5C3D10). Slightly desaturated.
No text.
IMPORTANT: The background (all areas outside the button shape) must be solid pure black (#000000).
Do NOT use alpha transparency — use solid black for all non-button areas.
```

---

### 5. btn_secondary_normal.png — サブボタン（通常）

**仕様:** 200×52px、黒背景PNG、NinePatch 左右20px・上下16px

**プロンプト（英語）:**

```
A smaller horizontal button background, 200x52 pixels.
Style: aged copper / dark bronze metallic plate. Less ornate than the primary brass button.
Rounded corners (~10px). Subtle raised bevel.
Left and right end-caps (each 20px) have a simple ridge ornament.
Color: dark copper (#8C4A2F to #6B3320). Warmer and more subdued than brass.
Center section (160px) is plain, designed to stretch.
No text.
IMPORTANT: The background (all areas outside the button shape) must be solid pure black (#000000).
Do NOT use alpha transparency — use solid black for all non-button areas.
```

---

### 6. btn_secondary_hover.png / btn_secondary_pressed.png

**プロンプト（英語）:**

btn_secondary_hover:
```
Same copper button (200x52px), but brighter — warm copper glow (#A85A38). No text.
IMPORTANT: The background (all areas outside the button shape) must be solid pure black (#000000).
Do NOT use alpha transparency.
```

btn_secondary_pressed:
```
Same copper button (200x52px), but darker and inset (#5A2A18, inverted bevel). No text.
IMPORTANT: The background (all areas outside the button shape) must be solid pure black (#000000).
Do NOT use alpha transparency.
```

---

### 7. logo_title.png — タイトル装飾フレーム

**仕様:** 480×160px、黒背景PNG。テキスト（"Nine Card Sort" / "ナインカードソート"）は **含めない**。テキストを収める装飾フレームのみ。

**プロンプト（英語）:**

```
A decorative title frame / ornamental border, 480x160 pixels.
Style: antique gold engraving, casino / Victorian parlor aesthetic.
The frame has:
- Horizontal ornamental bars (top and bottom) with flourishes — stylized acanthus leaves, scrollwork
- Left and right vertical end ornaments (small fleur-de-lis or similar)
- An open central area (roughly 360x100px) that is solid black — this is where text will be placed on top in the game engine
- The border itself is antique gold (#C9A84C), with etched line detail
No text inside the frame.
IMPORTANT: All areas outside the border AND the empty interior area must be solid pure black (#000000).
Do NOT use alpha transparency — use solid black for all non-gold areas.
```

---

### 8. panel_hud.png — 上部HUDパネル背景

**仕様:** 800×80px、黒背景PNG、NinePatch 左右16px・上下16px

**プロンプト（英語）:**

```
A wide horizontal panel background for a game HUD, 800x80 pixels.
Style: dark semi-transparent surface with a thin antique gold border on all sides.
Background fill: very dark green-black (#0D1A0D).
Border: 3px antique gold line (#C9A84C) with subtle inner shadow.
Top and bottom edges of the border have a faint ornamental line detail.
Left and right ends (16px each) have a slightly decorative corner trim.
The center area (768px wide) is plain — designed to stretch in NinePatch.
No icons, no text.
IMPORTANT: All areas outside the panel shape must be solid pure black (#000000).
Do NOT use alpha transparency — use solid black for all non-panel areas.
```

---

### 9. panel_ability_list.png — 能力一覧パネル背景

**仕様:** 320×400px、黒背景PNG、NinePatch 左右16px・上下16px

**プロンプト（英語）:**

```
A vertical rectangular panel background, 320x400 pixels.
Style: dark semi-transparent overlay panel with antique gold border — like a scoreboard in a Victorian casino.
Background: very dark forest green (#0D1A0D).
Border: 3px antique gold (#C9A84C) with a thin inner line creating a double-border effect.
Corner ornaments: small gold diamond or cross motif at each of the 4 corners (within the 16px margin).
Interior: plain dark fill — designed to stretch in NinePatch, will contain text labels.
No text, no icons.
IMPORTANT: All areas outside the panel shape must be solid pure black (#000000).
Do NOT use alpha transparency — use solid black for all non-panel areas.
```

---

### 10. card_face.png — カード表面

**仕様:** 100×148px、黒背景PNG。数字はGodotのLabelで後乗せするため **空白のカード**。

**プロンプト（英語）:**

```
A playing card face background, 100x148 pixels.
Style: aged ivory parchment / cream card stock with a thin decorative border.
Card body: warm cream/ivory (#F5E6C8), slightly textured like old paper.
Border: 4px antique gold frame with simple corner ornament (small diamond flourish at each corner).
Inner area: blank — no number, no suit symbol. This area will have text overlaid in the game.
Rounded corners (radius 8px).
No text, no symbols.
IMPORTANT: All areas outside the card shape (corners rounded off) must be solid pure black (#000000).
Do NOT use alpha transparency — use solid black for all non-card areas.
```

---

### 11. clear_ornament_top.png — クリア画面 上部装飾

**仕様:** 480×80px、黒背景PNG

**プロンプト（英語）:**

```
A horizontal ornamental header decoration, 480x80 pixels.
Style: antique gold engraving — a symmetrical flourish design used as a chapter heading ornament.
Features: central decorative motif (star, diamond, or small crest) flanked by flowing acanthus-leaf scrollwork extending to both sides.
The horizontal scrollwork fills roughly 80% of the width; both ends taper gracefully.
Color: antique gold (#C9A84C) with subtle engraved line detail.
No text.
IMPORTANT: All areas outside the gold ornament must be solid pure black (#000000).
Do NOT use alpha transparency — use solid black for all non-gold areas.
```

---

### 12. clear_ornament_bottom.png — クリア画面 下部装飾

**プロンプト（英語）:**

```
A horizontal ornamental footer decoration, 480x80 pixels.
Style: same antique gold engraving as the header ornament above, but mirrored vertically — designed to sit below content as a footer flourish.
Symmetrical scrollwork, antique gold (#C9A84C). No text.
IMPORTANT: All areas outside the gold ornament must be solid pure black (#000000).
Do NOT use alpha transparency — use solid black for all non-gold areas.
```

---

### 13. divider_gold.png — ゴールド区切り線

**仕様:** 400×12px、黒背景PNG

**プロンプト（英語）:**

```
A thin horizontal ornamental divider line, 400x12 pixels.
Style: antique gold ruled line with a small diamond or lozenge motif at the center.
The line tapers slightly near the left and right ends.
Color: antique gold (#C9A84C).
IMPORTANT: All areas outside the gold line must be solid pure black (#000000).
Do NOT use alpha transparency — use solid black for all non-gold areas.
```

---

### 14. result_card_bg.png — シェア用リザルトカード背景

**仕様:** 600×800px（縦長）、透過なし（不透明）。SNSシェア用にGodotのSubViewportでキャプチャ。

**プロンプト（英語）:**

```
A portrait-oriented parchment / aged paper background for a game result certificate, 600x800 pixels. NOT transparent — solid background.
Style: antique scroll / Victorian certificate / casino result slip.
Surface: warm ivory-cream parchment (#F2E4C4) with subtle staining, aging marks, and fine paper grain texture.
Border: a thick ornate antique gold frame (approximately 24px wide) around the entire image.
The frame has decorative corner pieces — elaborate gold flourishes at each of the 4 corners.
Along the top and bottom frame edges: a repeating small geometric gold ornament.
Interior: blank parchment — content (text, stats) will be overlaid by the game engine.
A faint central vertical axis line (barely visible, very light gold) can suggest a formal document structure.
The overall impression is a prestigious achievement certificate from a Victorian gentlemen's club.
No text. No icons in the interior.
```

---

### 15. result_card_line_premium.png — リザルトカード専用区切り線

**仕様:** 500×24px、黒背景PNG。SubViewport内のリザルトカード内で使用。

**プロンプト（英語）:**

```
A high-end ornamental horizontal divider line for a prestigious certificate, 500x24 pixels.
Style: intricate antique gold filigree.
The center features a prominent royal crest or elaborate floral jewel.
The line consists of double-ruled gold threads with delicate scrollwork, tapering elegantly at both ends.
Color: rich lustrous gold (#C9A84C).
IMPORTANT: All areas outside the gold line must be solid pure black (#000000).
Do NOT use alpha transparency — use solid black for all non-gold areas.
```

---

### 16. result_card_seal.png — リザルトカード印章

**仕様:** 96×96px、黒背景PNG

**プロンプト（英語）:**

```
A circular gold wax seal / emblem, 96x96 pixels.
Style: antique gold engraved seal — like a Victorian notary stamp.
Design: circular border with fine rope-twist or bead detail, containing a stylized playing card suit (spade ♠ or combination of all 4 suits) in the center.
Color: antique gold (#C9A84C) with dark engraved lines.
No text.
IMPORTANT: All areas outside the circular seal must be solid pure black (#000000).
Do NOT use alpha transparency — use solid black for all non-seal areas.
```

---

## 生成時の注意事項（Gemini へ）

1. **背景は純粋な黒 (#000000) で塗りつぶすこと。** アルファ透過（透明ピクセル）は使用しない。GodotのCanvasItemMaterial Blend Mode: Add（加算合成）により黒が透過される前提。例外: bg_velvet_green.png（タイル背景）と result_card_bg.png（シェア用不透明背景）。
2. **NinePatch用アセット**（btn_*, panel_*）は、端キャップ（マージン幅内）と中央伸縮エリアが視覚的に区別できるデザインにすること。端キャップに装飾、中央はシンプルな素材感のみ。
3. **スタイルの一貫性**：全アセットで同一のカラーパレット（ダークグリーン背景 / アンティークゴールド装飾 / 真鍮ボタン / アイボリーカード）を維持すること。
4. アセットごとに**1枚ずつ個別に生成**すること（複数アセットを1枚の画像に並べない）。

---

## Godot実装メモ（参考）

### NinePatchRect の設定方法
```
# btn_primary_normal.png を NinePatchRect に設定する場合
patch_margin_left = 24
patch_margin_right = 24
patch_margin_top = 18
patch_margin_bottom = 18
```

### Themeリソースでの管理（推奨）
```
# project.tres の Theme に登録
Button / normal    = btn_primary_normal.png  (NinePatchRect)
Button / hover     = btn_primary_hover.png
Button / pressed   = btn_primary_pressed.png
```

### result_card_bg.png の SubViewport キャプチャ構成
```
ResultCardViewport (SubViewport 600x800)
  └─ ResultCardBG (TextureRect: result_card_bg.png)
  └─ TitleText (Label)
  └─ StatsContainer (VBoxContainer)
  └─ Seal (TextureRect: result_card_seal.png)
```
