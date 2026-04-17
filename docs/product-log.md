## 2026-04-17 クリア画面にプレイ統計表示を追加

### 変更内容
- スキップ回数・各カードの能力発動回数をクリア画面に表示
- 能力名と回数を2カラムで右揃えにして視覚的に整列

### 変更ファイル
- `scripts/GameManager.gd`: `skip_count`・`ability_use_counts` 追跡変数を追加、ゲッター追加
- `scripts/Main.gd`: `_show_clear_screen` でスキップ回数と能力統計を表示、`_populate_ability_stats()` を追加
- `scenes/Main.tscn`: ClearScreenに `SkipCountLabel`・`StatsContainer` を追加、ボタン位置を下に移動

