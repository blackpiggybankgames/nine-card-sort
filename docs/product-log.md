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

## 2026-04-21: SNS連携シェア機能

### 変更内容
- クリア画面に「シェアする」ボタンを追加（「もう一度」の左隣に横並び配置）
- ボタン押下でスクリーンショット保存 + SNSテキストをクリップボードにコピー
- コピー完了時にトースト通知（2秒表示）を表示

### SNS連携テキスト仕様
- フリーモード: `Nine Card Sort をクリア！\n○○手でクリア\n#NineCardSort\n{URL}`
- デイリーモード: `Nine Card Sort デイリーチャレンジ（YYYY/MM/DD）をクリア！\n○○手でクリア\n#NineCardSort\n{URL}`
- 140字以内

### URL設定
- 本番: `https://blackpiggybankgames.github.io/nine-card-sort/`
- ドラフト（デバッグモード時）: `https://blackpiggybankgames.github.io/nine-card-sort/draft/`
- `config/game_balance.json` の `share` セクションで管理

### 変更ファイル
- `config/game_balance.json` — share設定追加
- `scripts/autoload/Config.gd` — `get_share_url()` / `get_share_hashtag()` 追加
- `scenes/Main.tscn` — ShareButton / CopyToastLabel 追加、RetryButton位置調整
- `scripts/Main.gd` — シェア機能3メソッド追加
