# Nine Card Sort

1〜9のカードを能力を使って昇順に並べるソリティアパズル。
Godot 4.3 / GDScript / Web Export / GitHub Pages配信。

## ドキュメント

| ドキュメント | 内容 |
|-------------|------|
| docs/CORE_RULES.md | ゲームコンセプト・基本ルール・設計思想 |
| docs/GAME_FLOW.md | ゲーム進行順序 |
| docs/GLOSSARY.md | ゲーム用語集 |
| docs/SYSTEM_SPEC.md | UI要素・物理パラメータ |
| docs/content/abilities.md | 能力定義（詳細） |
| docs/content/card_assignments.md | カード番号と能力の対応表 |
| docs/adr/ | 設計判断の記録（なぜこうしたか） |

| 作業 | 参照先 |
|------|--------|
| 能力変更・バランス調整 | .claude/skills/change-card/SKILL.md |
| ルール変更 | .claude/skills/change-rules/SKILL.md |
| バグ修正 | .claude/skills/fix-bug/SKILL.md |

## 設計ルール

### ゲームロジック
- 副作用禁止。GameStateを受け取り新しいGameStateを返す
- UIからゲームロジックを直接呼ばない

### 入力バリデーション
- Public関数の入口で行う

### パラメータ管理
- ゲームパラメータは config/game_balance.json で管理
- コードにハードコードしない

### 山札の配列規約
- index 0 = 一番上、index 8 = 一番下
- 能力発動時は発動カードを除外した8枚に対して操作（ADR-001参照）

## AI行動ルール

### 判断を仰ぐケース
以下は選択肢を2-3個、トレードオフ付きで提示し人間が決定:
- ゲームバランス・面白さ・手触りに関わる変更
- 能力の効果変更
- UI/UXの大きな変更

### パラメータ調整の提案形式
- ❌「〜が強すぎるから弱める」
- ✅「〜という遊び方を促したいから〜を調整」

### 作業完了時
- docs/temp/ の一時ドキュメントを本体に統合
- 統合完了後、一時ドキュメントを削除

### 基本姿勢
- 迷ったら実装せず質問
- コードには日本語コメントを付ける

## スキル

| スキル | 用途 | 引数 |
|--------|------|------|
| /change-card | カード能力の変更・バランス調整 | 一時ドキュメント名（任意） |
| /change-rules | ゲームルールの変更 | 一時ドキュメント名（任意） |
| /fix-bug | バグ修正 | バグ報告ドキュメント名（任意） |
| /sync-docs | ドキュメント同期チェック | - |

詳細手順は .claude/skills/<スキル名>/SKILL.md を参照。
使用例: `/change-card attack-buff-rework.md`
