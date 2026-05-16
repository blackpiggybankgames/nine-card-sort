# ボタンデバッグ要約（change-ui用）

ボタン関連のUI変更・修正に着手する前にこのファイルを読むこと。
詳細版は `docs/UI_BUTTON_GUIDE.md` を参照。

## 最重要事項

### Godot Button の描画は「状態スタイル＋focus上書き」の2層
1. 状態スタイル（disabled / pressed / hover / normal のいずれか1つ）
2. **`has_focus()` が true なら focus スタイルを上から重ね描き**

→ disabledやpressedなのに明るく見えるのは、**focus 残留 + focusスタイル(primary_hover)の上書き**が原因のことが多い。

### default_theme.tres の罠
- `Button/styles/focus = StyleBoxTexture_primary_hover` がデフォルト
- セカンダリ系ボタンを使っても、focus時はプライマリホバー画像が上書きされる
- シーン側で `focus_mode = 0` を設定すれば防げる

### ShaderMaterial_btn の COLOR 行
- `COLOR = col * COLOR;` の `* COLOR` を絶対に消さないこと
- modulate（StyleBox の modulate_color や Buttonノードの modulate）が効かなくなる

## 本プロジェクトの規約

- ゲームUIの Button は `focus_mode = 0` を原則とする（マウス/タップ前提）
- disabled の半透明化は `modulate_color = Color(0.55, 0.55, 0.55, 0.65)` が規約値
- セカンダリ系ボタンで focus_mode != 0 にする場合は `theme_override_styles/focus` も上書きする

## 症状→原因クイックチェック

| 症状 | 第一に疑う | 対処 |
|------|----------|------|
| disabledが明るい/半透明にならない | focus残留 | `focus_mode = 0` 追加 |
| pressed時に別画像になる | 同上 | `focus_mode = 0` 追加 |
| modulateが効かない | シェーダーの`* COLOR`消失 | `black_transparent.gdshader` 確認 |
| ホバー反応しない | focus_mode未設定 or focus残留 | `focus_mode = 0` 追加 |
| テキスト薄いが背景は明るい | focus上書きでdisabledが見えない | `focus_mode = 0` 追加 |

## 新規ボタン追加時の最低限チェック

- `material = SubResource("ShaderMaterial_btn")`
- `focus_mode = 0`
- `theme_override_styles/normal/hover/pressed/disabled` をすべて指定
- disabled状態を実機で目視確認
