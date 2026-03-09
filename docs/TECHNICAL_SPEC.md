# Technical Specification: Nine Card Sort

## Platform
- Engine: Godot 4.3
- Target: Web (HTML5)
- Resolution: 800 x 600
- Orientation: Landscape

---

## Scene Structure

```
Main (Node2D)
├── GameManager (Node)            # ゲーム状態の管理、手番制御
├── Deck (Node2D)                 # 山札全体の管理
│   └── CardSlots (Node2D)        # 各カードの表示位置管理
│       ├── Card_1 (Area2D)       # 数字1のカード
│       │   ├── Sprite2D
│       │   ├── CollisionShape2D
│       │   └── Label (数字表示)
│       ├── Card_2 (Area2D)       # 数字2のカード
│       │   └── ...（同上）
│       └── ... (Card_3 〜 Card_9)
├── UI (CanvasLayer)
│   ├── TurnCounter (Label)       # 手数表示
│   ├── UseAbilityButton (Button) # 能力を使うボタン
│   ├── SkipButton (Button)       # 能力を使わずに移動するボタン
│   └── AbilityDescription (Label) # 現在の一番上のカードの能力説明
├── TitleScreen (CanvasLayer)     # タイトル画面
│   ├── TitleLabel
│   └── StartButton
└── ClearScreen (CanvasLayer)     # クリア画面
    ├── CongratulationsLabel
    ├── TurnCountLabel
    └── RetryButton
```

---

## Physics Settings

- 物理エンジン: 2D
- Gravity: 0（カードゲームのため重力不使用）
- Physics FPS: 60

---

## Collision Layers

カード同士の衝突は使用しない。クリック検出のみ使用。

- Layer 1: Cards（クリック・タップ検出用）
- Layer 2: Buttons（UI操作用）

---

## Game Logic

### データ構造

```gdscript
# 山札は配列で管理（index 0 = 一番上）
var deck: Array[int] = []  # 例: [3, 7, 1, 5, 9, 2, 8, 4, 6]

# カードの能力はDictionaryで定義
# 注意: 能力は発動カード除外後の8枚に対して適用される
var card_abilities: Dictionary = {
    1: "任意の1枚を一番上へ移動",
    2: "任意の1枚を一番下へ移動",
    3: "一番上のカードを真ん中へ移動",
    4: "2番目のカードを一番下へ移動",
    5: "真ん中のカードを一番上へ移動",
    6: "下4枚の順序を逆転",
    7: "上4枚と下4枚を入れ替え",
    8: "8枚全体の順序を逆転",
    9: "足して9になる2枚を一番下へ移動"
}
```

### 手番処理フロー

```
手番開始
  ↓
一番上のカードを特定（deck[0]）
  ↓
能力説明をUIに表示
  ↓
プレイヤーの選択を待つ
  ├── [能力を使う] → 能力発動 → カードを一番下へ
  └── [スキップ]   → カードを一番下へ
  ↓
勝利判定チェック（deck == [1,2,3,4,5,6,7,8,9]）
  ↓
次の手番へ
```

### 能力の実装方針

```gdscript
func use_ability(card_number: int):
    match card_number:
        1: ability_move_to_top()        # 任意の1枚を一番上へ
        2: ability_move_to_bottom()     # 任意の1枚を一番下へ
        3: ability_top_to_middle()      # 一番上を真ん中へ
        4: ability_drop_second()        # 2番目を一番下へ
        5: ability_middle_to_top()      # 真ん中を一番上へ
        6: ability_reverse_bottom4()    # 下4枚を逆順
        7: ability_swap_blocks()        # 上4枚と下4枚を入れ替え
        8: ability_full_reverse()       # 8枚全体を逆順
        9: ability_sum9_to_bottom()     # 足して9になる2枚を一番下へ
```

---

## Input Mapping

| アクション | キーボード | マウス / タッチ |
|-----------|-----------|--------------|
| 能力を使う | Space | UseAbilityButtonをクリック |
| スキップ   | Enter | SkipButtonをクリック |
| カードを選ぶ（能力対象） | 1〜9キー | カードをクリック |

---

## Asset Requirements

| ファイル名 | サイズ | 説明 |
|-----------|-------|------|
| card_back.png | 100x150px | カードの裏面 |
| card_front_base.png | 100x150px | カード表面のベース |
| card_1.png 〜 card_9.png | 100x150px | 各数字カード（またはベース+動的テキスト） |
| bg_game.png | 800x600px | ゲーム背景 |
| bg_title.png | 800x600px | タイトル背景 |
| se_move.wav | - | カード移動効果音 |
| se_ability.wav | - | 能力発動効果音 |
| se_clear.wav | - | クリア効果音 |
| bgm_game.ogg | - | ゲームBGM |

> **開発初期はプレースホルダーとして、GDScriptで動的に生成したシンプルな矩形＋テキストで代用可**

---

## Performance Targets

- 60 FPS（モダンブラウザ）
- 初回ロード時間: 3秒以内
- バンドルサイズ: 5MB以下
