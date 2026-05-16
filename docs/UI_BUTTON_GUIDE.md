# UIボタン仕様メモ

Godot 4 / 本プロジェクトでButtonを扱う際の暗黙知をまとめたもの。
ボタンの追加・修正・デバッグ前に必読。

## 1. Godot Button の描画レイヤー順序

Godot 4 の `Button._notification(NOTIFICATION_DRAW)` は次の順で描画する:

1. **状態スタイル**（1つだけ選択され描画される）
   - 優先順位: `disabled` > `pressed` / `hover_pressed` > `hover` > `normal`
2. **focus スタイル**を**上から重ね描き**する（`has_focus()` が true の場合）
3. テキスト・アイコンを描画

> 注意: focus は「他のスタイルを置き換える」のではなく「**他のスタイルの上に重ねる**」。
> したがって `disabled` 状態で focus を持っていると、disabled の見た目に focus テクスチャが上書きされる。

## 2. default_theme.tres の継承内容

`assets/default_theme.tres` で全Buttonに対するデフォルトスタイルを定義している:

| 状態 | デフォルト |
|------|-----------|
| normal | `StyleBoxTexture_primary_normal`（金/木製） |
| hover | `StyleBoxTexture_primary_hover`（金/木製・明るい） |
| pressed | `StyleBoxTexture_primary_pressed` |
| disabled | `StyleBoxTexture_primary_disabled`（modulate半透明） |
| **focus** | **`StyleBoxTexture_primary_hover`** ← 重要 |

**シーンで `theme_override_styles/focus` を上書きしないと、すべてのButtonは focus時に「明るいプライマリホバー画像」を上から重ねる。**

セカンダリ系ボタンを使っていても、focusスタイルは継承でプライマリになる。これが原因でセカンダリ系の見た目が壊れることが多い。

## 3. ShaderMaterial_btn の COLOR 合成式

`assets/shaders/black_transparent.gdshader`:

```gdshader
void fragment() {
    vec4 col = texture(TEXTURE, UV);
    float maxChan = max(max(col.r, col.g), col.b);
    // 純粋な黒のみ透明にする（暗い茶色のボタン本体は透過しない）
    col.a = min(col.a, smoothstep(0.02, 0.1, maxChan));
    // * COLOR でGodotの頂点カラーを乗算（disabled状態の暗転を反映させる）
    COLOR = col * COLOR;
}
```

ポイント:
- `COLOR` は Godot から渡される頂点カラー（StyleBoxTexture の `modulate_color` や Buttonノードの `modulate` プロパティが乗算で合成されたもの）
- `col * COLOR` の `* COLOR` を消すと、modulate が一切効かなくなる（disabled暗転も無効化される）。**過去にこのバグを踏んでいるので絶対に消さないこと**
- 純粋な黒ピクセルは smoothstep で透明化される。テクスチャの背景に意図的に黒を使うとそこが抜ける

## 4. このプロジェクトの規約

### 4.1 `focus_mode = 0` を原則とする
- ゲームUIのButton（Main.tscn の GameUI 配下）は `focus_mode = 0`（FOCUS_NONE）にする
- 理由:
  - キーボードナビゲーションを使わないマウス/タップ前提のUIなので、focus残留によるスタイル上書き事故を避ける
  - 「クリック後もホバーが正常に反応する」（`Main.gd:674` のコメント参照）
- 既存例: タイトル画面の TextureButton（`Main.gd:682`）、GameUIのUseAbility/Skip/Cancel/Undoボタン

### 4.2 セカンダリ系ボタンの `theme_override_styles/focus` 上書き
- セカンダリ系（gray/leather）ボタンを使う場合、デフォルトテーマの focus（primary_hover）を継承するとセカンダリの見た目が壊れる
- 対策: `theme_override_styles/focus = SubResource("StyleBoxTexture_secondary_hover")` を明示する
- ただし `focus_mode = 0` を設定していれば不要（focus自体が起きないため）

### 4.3 disabled スタイルは `modulate_color` で半透明グレー化
- 規約値: `Color(0.55, 0.55, 0.55, 0.65)`
- プライマリ系: `StyleBoxTexture_primary_disabled` を使う（テクスチャは normal と同じ `21_btn_pn`）
- セカンダリ系: `StyleBoxTexture_secondary_disabled` を使う（テクスチャは normal と同じ `7_btn_sn`）

## 5. 症状→原因チェックリスト

| 症状 | 第一に疑うこと | 確認方法 |
|------|---------------|----------|
| disabledなのに明るく見える / 半透明にならない | **focus残留 + テーマfocus=primary_hover の重ね描き** | 該当ボタンに `focus_mode = 0` があるか確認 |
| pressed したら別系統の画像に切り替わる | **同上**（focusのprimary_hoverが上書き） | `focus_mode = 0` を追加 |
| modulate（StyleBox modulate_color）が効かない | シェーダーの `COLOR = col * COLOR` の `* COLOR` が消えていないか | `assets/shaders/black_transparent.gdshader` を確認 |
| ホバーが反応しない / 色が切り替わらない | `focus_mode` が NONE 以外になっている、またはfocus残留 | TextureButton ならまず `focus_mode = Control.FOCUS_NONE` |
| テキストだけ薄く、背景が明るいまま | テキストはdefault themeの`font_disabled_color`、背景は focus 上書き | `focus_mode = 0` を追加 |
| `theme_override_styles/...` が効いていない気がする | テーマ継承で別の値が使われている可能性。または focus 重ね描きで見えない | `default_theme.tres` の該当キーを確認 |

## 6. 新規ボタン追加時のチェックリスト

シーンに新規Button（または互換ノード）を追加する際:

- [ ] `material = SubResource("ShaderMaterial_btn")` を設定したか
- [ ] `focus_mode = 0` を設定したか（マウス/タップ前提UIなら必須）
- [ ] `theme_override_styles/normal/hover/pressed/disabled` をすべて指定したか
- [ ] セカンダリ系を使う場合、focus_mode=0 でなければ `theme_override_styles/focus` も上書きしたか
- [ ] disabled 状態のテストをしたか（プログラムから `disabled = true` を設定して目視確認）

## 関連ファイル

- `scenes/Main.tscn` — ボタン定義の本体
- `assets/default_theme.tres` — テーマのデフォルト値
- `assets/shaders/black_transparent.gdshader` — ボタン用シェーダー
- `scripts/Main.gd:674` — TextureButton動的生成時の focus_mode = NONE 設定例
- `docs/ui-log.md` — UI変更履歴（過去の修正内容を参照する場合）
