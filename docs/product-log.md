## 2026-04-17 クリア画面にプレイ統計表示を追加

### 変更内容
- スキップ回数・各カードの能力発動回数をクリア画面に表示
- 能力名と回数を2カラムで右揃えにして視覚的に整列

### 変更ファイル
- `scripts/GameManager.gd`: `skip_count`・`ability_use_counts` 追跡変数を追加、ゲッター追加
- `scripts/Main.gd`: `_show_clear_screen` でスキップ回数と能力統計を表示、`_populate_ability_stats()` を追加
- `scenes/Main.tscn`: ClearScreenに `SkipCountLabel`・`StatsContainer` を追加、ボタン位置を下に移動


## 2026-04-17: デイリーチャレンジモード追加

### 変更内容
- タイトル画面に「フリープレイ」と「デイリーチャレンジ」ボタンを追加
- 既存のスタートボタンを「フリープレイ」にリネーム
- デイリーチャレンジはJST（UTC+9）の日付をシードにした固定配列でプレイ
- リトライ時は前回のモード（フリー/デイリー）を引き継ぐ

### 変更ファイル
- `scenes/Main.tscn`: ボタン2つに変更
- `scripts/Deck.gd`: `shuffle_deck(seed)` にシード引数追加
- `scripts/GameManager.gd`: `start_game(daily_mode)`, `get_daily_seed()` 追加、`is_daily_mode` フラグ追加
- `scripts/Main.gd`: `_on_daily_challenge_button_pressed()` 追加、リトライ時モード引き継ぎ
- `tests/test_game_manager.gd`: デイリーモード関連テスト6件追加

### タイムゾーン設計
- JST固定（UTC+9）: 日本語ゲームのため日本時間の深夜0時で切替
