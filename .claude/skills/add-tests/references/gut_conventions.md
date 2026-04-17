# GUT テストコード規約

## ファイル構成

```
tests/
  test_game_state.gd      # GameState操作・勝利判定
  test_abilities.gd       # 各カードの能力ロジック
  test_validation.gd      # 入力バリデーション
  .gutconfig.json         # GUT設定
```

## テストクラスの基本構造

```gdscript
extends GutTest

# テスト前の共通セットアップ
func before_each():
    pass

# テスト後のクリーンアップ
func after_each():
    pass

# テスト関数（必ず func test_ で始める）
func test_example():
    # Arrange（準備）
    var state = GameState.new([3, 1, 2, 4, 5, 6, 7, 8, 9])

    # Act（実行）
    var result = state.is_sorted()

    # Assert（検証）
    assert_false(result, "ソートされていない状態はfalseを返す")
```

## よく使うアサーション

| アサーション | 用途 |
|-------------|------|
| `assert_eq(a, b, "msg")` | a == b |
| `assert_ne(a, b, "msg")` | a != b |
| `assert_true(val, "msg")` | val が true |
| `assert_false(val, "msg")` | val が false |
| `assert_null(val, "msg")` | val が null |
| `assert_not_null(val, "msg")` | val が null でない |

## 命名規則

- テスト関数: `test_<対象>_<条件>_<期待結果>()`
- 例: `test_is_sorted_when_ascending_returns_true()`
- 日本語コメントで意図を説明する

## テストの独立性

- 各テスト関数は独立して動作すること
- グローバル状態を変更しない
- `before_each` でテスト用の状態を毎回初期化する
