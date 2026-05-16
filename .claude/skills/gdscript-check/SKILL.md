---
name: gdscript-check
description: >
  GDScript（Godot 4.3）の記述ルールに沿ったセルフチェックを行う。
  各スキルが GDScript コードを書いた後に自動で呼び出す内部スキル。
  「gdscript-check を実行」「GDScript をチェックして」と言われたときも使用。
---

## モデル分担
- **チェックフェーズ**（手順 1〜2）: `Agent` ツール（`model=opus`, `subagent_type=Explore`）に委譲してファイル読み取り・規則違反を検出する
- **修正フェーズ**（手順 3〜4）: デフォルトモデルで修正・報告を行う

## 手順

1. 変更した GDScript ファイルを読む（引数で指定、または直前のスキルで編集したファイル）
2. 下記チェック規則に照らして違反箇所を探す
3. 違反があれば即座に修正する
4. 「GDScript チェック: 問題なし」または「GDScript チェック: X 件修正」と報告して終了

---

## チェック規則（Godot 4.3）

### 規則 1. `min()` / `max()` の戻り値を型付き変数に代入しない

`min()` / `max()` の戻り値は `Variant`。型注釈付き変数への直接代入はエラー。

```gdscript
# NG
var x: float = min(a, b)

# OK: 三項演算子で代替
var x: float = a if a <= b else b
```

### 規則 2. `minf` / `mini` / `maxf` / `maxi` を使用しない

GDScript の `@GlobalScope` に存在しない（C++ 専用）。呼び出すとパースエラー。

```gdscript
# NG（パースエラー）
var x: float = minf(a, b)

# OK
var x: float = a if a <= b else b
```

### 規則 3. メソッドチェーンに `:=` を使わない

Godot 4.3 の型推論はメソッドチェーン全体を解析できない場合がある。

```gdscript
# NG（型推論エラー）
var vp := get_viewport().size

# OK: 戻り値の型を明示する
var vp: Vector2i = get_viewport().size
```
