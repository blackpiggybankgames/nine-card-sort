---
name: run-tests
description: >
  テストをCLIで実行して結果を確認する。
  「テストを実行」「テストを走らせて」
  他のスキル（fix-bug, change-card等）から自動で呼び出される。
  前提: GUT（Godot Unit Test）が addons/gut/ に導入済みであること。
---

## 手順
1. `tests/` ディレクトリが存在するか確認
   - 存在しない → 「テストが未実装です」と報告して終了
2. Godot CLIでテストを実行
   ```
   godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/ -gexit
   ```
3. 結果を解釈して報告
   - 全件パス → 「テスト通過: X件」と報告
   - 失敗あり → 失敗したテスト名・エラー内容を報告

## 結果の報告フォーマット

### パスした場合
```
テスト結果: 全件通過 (X件)
```

### 失敗した場合
```
テスト結果: X件失敗 / Y件中

失敗:
- test_game_state.gd::test_is_sorted → AssertionError: expected true, got false
```

## エラーパターン

| 状況 | 対処 |
|------|------|
| `godot` コマンドが見つからない | Godotのパスを確認するよう案内する |
| GUTが未導入 | 「addons/gut/ が見つかりません」と報告して停止 |
| テストが存在しない | 「テストが未実装です。/add-tests で作成できます」と報告 |
| テストが失敗 | 失敗内容を呼び出し元に返す（呼び出し元が対処を判断） |
