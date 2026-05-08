# スマートフォン画面対応 作業計画書

作成日: 2026-05-07  
担当AI: Claude Sonnet 4.6  
1日の作業上限: 2時間

---

## 概要

現在のゲームはPC向け横長（800×600）で設計されており、スマートフォン（縦向き）で表示すると UIが崩れる。  
`canvas_items` + `expand` のストレッチ設定により、縦長スマホでは仮想キャンバスが約 **800×1731px** に拡張されるため、  
600px 想定で設計された要素が大きくズレる。

スマートフォン対応には **レイアウト崩れの修正** だけでなく、**指で操作できるタッチターゲットサイズの確保** も必要。

### 主な症状

| 画面 | 症状 | 原因ノード |
|------|------|-----------|
| クリア画面 | 能力リストがボードの外（画面中央）に表示される | `StatsContainer`（center アンカー） |
| タイトル画面 | ボタンが画面上部に偏り、下に大きな空白 | `StartButton` / `DailyChallengeButton`（固定 y 座標） |
| 全画面 | ボタンが指でタップできないほど小さい | PC 向けサイズ（高さ 50px 仮想 ≈ 24px 実際）のまま |
| ゲーム画面 | 上下の UI が間延びする | ボタン間隔の問題（軽微） |

### 修正方針

- **ストレッチ設定は変更しない**（`canvas_items` + `expand` を維持）
- 起動時・リサイズ時に viewport サイズを取得し、縦長と横長でレイアウトを切り替える
- portrait 判定：`viewport.size.y > viewport.size.x`
- 横長（PC）は現状維持。縦長（スマホ）のみ追加対応
- **タッチターゲット最小サイズ**: 44px logical（Apple HIG）= 仮想 **90px** 以上（390px 幅基準）

---

## 前提知識

### 仮想キャンバスサイズの計算

```
スマホ実画面（logical px）: 390×844
スケール = 390 / 800 = 0.4875
仮想キャンバス = 800 × (844 / 0.4875) ≈ 800×1731
```

portrait 時の各レイアウト基準値:
- 画面中央 Y = 865
- 画面下端 Y ≈ 1731
- ResultBoard は y=7〜513（上部に固定）→ 変更不要
- カードは viewport.y × 0.45 ≈ 779（動的配置済）→ 変更不要

### タッチターゲットサイズの計算

```
最小 logical px = 44px（Apple HIG）/ 48px（Android）
仮想px換算 = 44 / 0.4875 ≈ 90px
→ portrait 時のボタン高さは仮想 90px 以上が必要
```

現在のボタン高さ（仮想 50px）= logical 24px → 指でのタップには不十分

### 変更が必要なノード一覧

| ノード | 問題 | 修正方法 |
|--------|------|---------|
| `UILayer/ClearScreen/StatsContainer` | center アンカー → portrait で y=696 に落ちる | top アンカーに変更（静的）✅ 完了 |
| `UILayer/ClearScreen/ClearModeLabel` | top アンカー y=111 → 問題なし | 変更不要 |
| `UILayer/ClearScreen/ShareButton` 他3ボタン | top アンカー y=518 → 位置は問題なし / サイズは小さい | サイズ拡大（Day3） |
| `UILayer/TitleScreen/StartButton` | 固定 y=320 → portrait で画面上1/5に偏る / サイズも小さい | 動的配置✅ 完了 / サイズ拡大（Day3） |
| `UILayer/TitleScreen/DailyChallengeButton` | 固定 y=385 → 同上 | 動的配置✅ 完了 / サイズ拡大（Day3） |
| `UILayer/TitleScreen/LogoFrame` | 横幅 780px → portrait の 800px に収まる（ギリギリ） | 変更不要と判断（実測で確認済み） |
| `UILayer/GameUI/UseAbilityButton` | タッチターゲットが小さい | portrait 時にサイズ拡大（Day4） |
| `UILayer/GameUI/SkipButton` | 同上 | portrait 時にサイズ拡大（Day4） |
| `DeckDisplay`（カード間隔） | 9枚×80px=720px → 800px 内に収まるが余裕なし | portrait 時に 60px 程度に縮小（Day4） |

---

## 作業計画

### Day 1（2h）: 調査・基盤実装 ✅ 完了（2026-05-07）

**目標**: portrait 判定の共通関数を実装し、全ノードの現状を整理する

#### AI 作業（1.5h）✅

1. `Main.gd` に以下の関数を追加する

```gdscript
# portrait/landscape の判定
func _is_portrait() -> bool:
    return get_viewport().size.y > get_viewport().size.x

# レイアウト切り替えのエントリポイント
func _setup_responsive_layout() -> void:
    if _is_portrait():
        _apply_portrait_layout()
    else:
        _apply_landscape_layout()

func _apply_portrait_layout() -> void:
    pass  # Day2〜4 で実装

func _apply_landscape_layout() -> void:
    pass  # 現状維持（何もしない）
```

2. `_ready()` の末尾に `_setup_responsive_layout()` を呼び出しを追加
3. `get_viewport().size_changed.connect(_setup_responsive_layout)` を追加（回転対応）
4. コミット・プッシュ

#### 人間 作業（0.5h）✅

- スクリーンショット撮影済み（iPhone 12 Pro: 390×844、DevTools）
  - `docs/temp/Day1タイトル画面.png`
  - `docs/temp/Day1ゲーム画面.png`
  - `docs/temp/Day1クリア画面.png`

#### スクリーンショットから確認した現状（Day2以降の作業メモ）

| 画面 | 観察された問題 |
|------|--------------|
| タイトル画面 | ロゴ+ボタンが画面上1/3に集まり、下半分が空白 |
| ゲーム画面 | カードは中央付近に表示されている（比較的良好）。上部パネル・下部ボタンは表示されているが上下に大きな余白あり |
| クリア画面 | リザルトボードは上部に表示されるが、StatsContainer（能力リスト）がボード内に表示されていない（空のまま） |

**完了確認**: コードがエラーなく動作すること（動作自体は変わらない）✅

---

### Day 2（2h）: クリア画面修正 ✅ 完了（2026-05-07）

**目標**: クリア画面の能力リストがボード内に正しく表示されること

#### AI 作業 ✅

`Main.tscn` の StatsContainer アンカーを TOP_CENTER に変更:
- `anchors_preset = 8 → 5`、`anchor_top = 0.5 → 0.0`、`anchor_bottom = 0.5 → 0.0`
- `offset_top = -169.5 → 130.5`、`offset_bottom = 191.5 → 491.5`
- PC 表示の絶対座標（y=130.5〜491.5）は変わらず。クリア画面ボタン（offset_top=518）は変更不要と確認。

#### 人間 作業 ✅

- `docs/temp/Day2クリア画面.png` で確認済み

**完了確認**: スマホサイズでクリア画面の能力リストがボード内に表示される ✅

---

### Day 3（2h）: タイトル画面修正

**目標**: スマホでタイトル画面のボタンが中央に配置され、指でタップできるサイズになること

#### AI 作業

**作業1: タイトルボタンの動的配置** ✅ 完了

`_apply_portrait_layout()` に追加済み:
- StartButton: `center_y - 80` 〜 `center_y - 30`（高さ 50px 仮想）
- DailyChallengeButton: `center_y - 10` 〜 `center_y + 40`（高さ 50px 仮想）
- `_apply_landscape_layout()` で元の値（y=320/385）に戻す

**作業2: タイトルボタンのサイズ拡大**（残作業）

portrait 時の高さ 50px → **90px** に拡大、幅も **280px** に拡大（現在 200px）。
ボタン間隔 20px を確保してペアを中央付近に配置:

```gdscript
# ボタンペア全体（90+20+90=200px）を center_y に中央揃え
var btn_top = center_y - 100.0
start_button.offset_left = -140.0
start_button.offset_right = 140.0
start_button.offset_top = btn_top
start_button.offset_bottom = btn_top + 90.0
daily_button.offset_left = -140.0
daily_button.offset_right = 140.0
daily_button.offset_top = btn_top + 110.0
daily_button.offset_bottom = btn_top + 200.0
```

landscape 時は元の値（offset_left=-100、offset_right=100、高さ 50px）に戻す。

**作業3: クリア画面ボタンのサイズ拡大**（残作業）

ShareButton / RetryButton / TitleButton も portrait 時に高さ 90px に拡大。
現在の layout（y=518〜558、高さ 40px）→ y=518〜608（高さ 90px）に変更。

**作業4: コミット・プッシュ**

#### 人間 作業

- タイトル画面をスマホサイズで再確認
- ボタンの大きさ・位置・押しやすさを確認
- `docs/temp/Day3タイトル画面v2.png` などで保存してフィードバック

**完了確認**: スマホでボタンが指でタップできる大きさで中央付近に表示される

---

### Day 4（2h）: ゲーム画面修正 ✅ 完了（2026-05-08）

**目標**: スマホでゲーム画面のボタンが押しやすく、カードが操作できること

#### AI 作業（1.5h）

**作業1: ゲーム画面ボタンのサイズ拡大**

`UseAbilityButton` / `SkipButton` のサイズ・位置を portrait 時に拡大。
現在の値を `Main.tscn` から読んでから実装する。

**作業2: portrait 時のカード間隔縮小**

`DeckDisplay.gd` の `_update_position()` を修正:

```gdscript
func _update_position() -> void:
    var viewport_size = get_viewport().size
    position = Vector2(viewport_size.x / 2, viewport_size.y * 0.45)
    
    # portrait 時はカード間隔を縮小
    if viewport_size.y > viewport_size.x:
        card_spacing = 60.0  # portrait: 80→60
    else:
        card_spacing = 80.0  # landscape: 通常値
    
    _update_card_positions_immediately(current_deck)
```

**作業3: ゲーム画面 TopPanel・テキスト確認**

- TopPanel は全幅アンカーで上部固定 → 変更不要
- AbilityName / AbilityDescription ラベルが portrait で見切れないか確認

**作業4: コミット・プッシュ**

#### 人間 作業（0.5h）

- ゲーム画面をスマホサイズで実際にプレイして確認
  - カードが全部見えるか
  - ボタンが指で押せるか
  - 能力名テキストが見切れないか
- フィードバックを提供

#### 人間 作業 ✅

- `docs/temp/Day4ゲーム画面修正後_390_844.png` で確認済み

**完了確認**: スマホでゲームが一通りプレイできること ✅

---

### Day 5（2h）: 全体テスト・修正

**目標**: 複数端末サイズで全画面が正常に動作すること

#### 人間 作業（1h）

DevTools で下記サイズを順番に確認し、問題をリストアップ:

| 端末 | サイズ | チェック画面 |
|------|--------|------------|
| iPhone SE | 375×667 | タイトル・ゲーム・クリア |
| iPhone 15 | 390×844 | タイトル・ゲーム・クリア |
| Android 標準 | 412×915 | タイトル・ゲーム・クリア |
| iPad | 768×1024 | タイトル・ゲーム・クリア |
| PC Chrome | 1280×720 | タイトル・ゲーム・クリア |

問題点を `docs/temp/` にメモとして保存

#### AI 作業（1h）

- 人間からのフィードバックをもとに残課題を修正
- `CancelButton`（能力選択中のみ表示）を portrait 時に高さ 160px に拡大（Day4 では対応外）
- コミット・プッシュ

**完了確認**: 上記5サイズで主要な崩れがないこと

---

### Day 6（2h）: 仕上げ・後処理

**目標**: 残課題の解消とドキュメント整理

#### AI 作業（1.5h）

- Day 5 のテストで残った問題を修正
- `docs/SYSTEM_SPEC.md` にレスポンシブ対応の仕様を追記
- `docs/temp/smartphone-layout-plan.md`（本ファイル）を削除
- 最終コミット・プッシュ

#### 人間 作業（0.5h）

- 最終確認（実機スマホでのテスト推奨）
- GitHub Pages にデプロイされた本番環境で動作確認

**完了確認**: 実機スマホでゲームが正常にプレイできること

---

## 合計見積もり

| | 人間 | AI | 合計 |
|--|------|-----|------|
| Day 1 | 0.5h | 1.5h | 2h |
| Day 2 | 0.5h | 1.5h | 2h |
| Day 3 | 0.5h | 1.5h | 2h |
| Day 4 | 0.5h | 1.5h | 2h |
| Day 5 | 1.0h | 1.0h | 2h |
| Day 6 | 0.5h | 1.5h | 2h |
| **合計** | **3.5h** | **8.5h** | **12h** |

---

## リスク・補足

| リスク | 対応方針 |
|--------|---------|
| `size_changed` シグナルが想定外のタイミングで発火する | デバウンス処理を追加（0.1秒待機） |
| カード間隔縮小で能力選択のタップ精度が落ちる | カードサイズも縮小（80%）して対応 |
| 横向き→縦向き切り替え時にアニメーション中の状態が崩れる | ゲーム中の orientation 変更は無視（警告表示のみ） |
| iPad（768×1024）で portrait 判定されるが表示が崩れる | 768px 以上は landscape 扱いにする閾値を設ける |
| ボタン拡大でテキストが枠からはみ出す | font_size を portrait 時に縮小して対応 |

---

## AI への引き継ぎ事項

作業開始時は必ず以下を確認すること:

1. `docs/temp/smartphone-layout-plan.md`（本ファイル）を読む
2. `scenes/Main.tscn` の対象ノードの現在値を読んでから変更する
3. 各 Day の作業後に必ずコミット・プッシュする
4. 人間のフィードバックを待ってから次 Day に進む
