extends Node
class_name GameManager

# ゲーム全体の状態と手番を管理するクラス

signal turn_started(top_card: int)      # 手番開始時
signal turn_ended                        # 手番終了時
signal ability_used(card: int)           # 能力使用時
signal target_selection_required(card: int)  # 対象選択（1段階目）が必要な時
signal target_selection_step2_required(card: int, first_target: int)  # 2段階選択の2段階目が必要な時
signal game_cleared(turn_count: int)     # ゲームクリア時
signal ability_ready(card: int, target1: int, target2: int, ability_card: int)  # アニメーション付き発動要求

# ゲームの状態
enum GameState {
	TITLE,           # タイトル画面
	PLAYING,         # プレイ中
	SELECTING_TARGET, # 対象選択中
	CLEARED          # クリア
}

var current_state: GameState = GameState.TITLE
var turn_count: int = 0
var skip_count: int = 0
var ability_use_counts: Dictionary = {}  # カード番号 → 能力発動回数
var deck: Deck
var is_daily_mode: bool = false

# カード8のフリップ状態（false=表面、true=裏面）
# 表面で発動 → 裏面に。裏面で発動 → 任意カードを移動 → 表面に戻る
var card8_flipped: bool = false

# 対象選択中の情報
var selecting_ability: int = -1  # 現在選択中の能力
var selected_targets: Array[int] = []  # 選択済みの対象


func _ready() -> void:
	# Deckノードを取得（子ノードとして追加されている前提）
	deck = Deck.new()
	add_child(deck)

	# シグナル接続
	deck.game_won.connect(_on_game_won)


# ゲームを開始する（daily_mode=trueでJST日付固定シードを使用）
func start_game(daily_mode: bool = false) -> void:
	is_daily_mode = daily_mode
	current_state = GameState.PLAYING
	turn_count = 0
	skip_count = 0
	ability_use_counts = {}
	for i in range(1, 10):
		ability_use_counts[i] = 0
	card8_flipped = false
	if daily_mode:
		deck.shuffle_deck(get_daily_seed())
	else:
		deck.shuffle_deck()
	_start_turn()


# JST（UTC+9）の今日の日付をシードに変換する（YYYYMMDD形式の整数）
func get_daily_seed() -> int:
	var jst_unix = Time.get_unix_time_from_system() + 9 * 3600
	var d = Time.get_date_dict_from_unix_time(jst_unix)
	return d["year"] * 10000 + d["month"] * 100 + d["day"]


# 手番を開始する
func _start_turn() -> void:
	if current_state != GameState.PLAYING:
		return

	var top_card = deck.get_top_card()
	turn_started.emit(top_card)


# 能力を使わずにスキップ（一番上を一番下へ移動のみ）
func skip_ability() -> void:
	if current_state != GameState.PLAYING:
		return

	turn_count += 1
	skip_count += 1
	deck.move_top_to_bottom()
	turn_ended.emit()

	# 勝利していなければ次の手番へ
	if current_state == GameState.PLAYING:
		_start_turn()


# 能力を使用する
func use_ability() -> void:
	if current_state != GameState.PLAYING:
		return

	var top_card = deck.get_top_card()

	# 対象選択が必要な能力かどうかをチェック
	if _requires_target_selection(top_card):
		current_state = GameState.SELECTING_TARGET
		selecting_ability = top_card
		selected_targets.clear()
		target_selection_required.emit(top_card)
	else:
		# 対象選択不要な能力はアニメーション付き発動を要求
		ability_ready.emit(top_card, -1, -1, top_card)


# 対象選択が必要な能力かどうか
func _requires_target_selection(card: int) -> bool:
	# 2: 3枚グループの先頭カードを選択
	# 4: どかすカードを選択（端以外）
	# 9: ペアトップカードを選択
	# 1, 6, 7: 2段階選択（1段階目が必要）
	# 8: 裏面のときのみ2段階選択
	if card == 8:
		return card8_flipped
	return card in [1, 2, 4, 6, 7, 9]


# 2段階選択が必要な能力かどうか
func _requires_two_steps(card: int) -> bool:
	# 1: ソースカード → ±1ターゲットカード
	# 6: 1組目ペアトップ → 2組目ペアトップ
	# 7: ブロック中央カード → ギャップ右側カード（矢印）
	# 8（裏面）: 移動カード → 挿入位置カード
	if card == 8:
		return card8_flipped
	return card in [1, 6, 7]


# 対象を選択する（UI側から呼ばれる）
func select_target(card_number: int) -> void:
	if current_state != GameState.SELECTING_TARGET:
		return

	if selected_targets.size() == 0:
		# 1段階目の選択
		selected_targets.append(card_number)
		if _requires_two_steps(selecting_ability):
			# 2段階目の選択を促す
			target_selection_step2_required.emit(selecting_ability, card_number)
		else:
			# 1段階選択で完了 - アニメーション付き発動を要求
			ability_ready.emit(selecting_ability, card_number, -1, selecting_ability)

	elif selected_targets.size() == 1:
		# 2段階目の選択 - アニメーション付き発動を要求
		selected_targets.append(card_number)
		ability_ready.emit(selecting_ability, selected_targets[0], selected_targets[1], selecting_ability)


# 対象選択をキャンセルする
func cancel_target_selection() -> void:
	if current_state != GameState.SELECTING_TARGET:
		return

	current_state = GameState.PLAYING
	selecting_ability = -1
	selected_targets.clear()
	_start_turn()


# 能力を実際に実行する（Main.gdのアニメーション完了後に呼ばれる）
# original_top_card: 手番開始時に一番上だったカード（能力発動カード）
func commit_ability_execution(card: int, target1: int = -1, target2: int = -1, original_top_card: int = -1) -> void:
	# 能力発動カードを山札から取り除く（能力の効果対象にならないようにする）
	var ability_card = original_top_card if original_top_card != -1 else card
	deck.remove_card(ability_card)

	# 能力を実行（発動カードがない状態で）
	var success = deck.use_ability(card, target1, target2)

	if success:
		ability_used.emit(card)
		turn_count += 1
		ability_use_counts[card] = ability_use_counts.get(card, 0) + 1

		# カード8のフリップ状態をトグル
		if card == 8:
			card8_flipped = !card8_flipped

		# 能力発動カードを一番下に追加
		deck.add_card_to_bottom(ability_card)

		current_state = GameState.PLAYING
		selecting_ability = -1
		selected_targets.clear()

		turn_ended.emit()

		# 勝利していなければ次の手番へ
		if current_state == GameState.PLAYING:
			_start_turn()
	else:
		# 能力が失敗した場合は発動カードを元に戻す
		deck.cards.insert(0, ability_card)
		deck.deck_changed.emit()


# ゲームクリア時の処理
func _on_game_won() -> void:
	current_state = GameState.CLEARED
	game_cleared.emit(turn_count)


# タイトル画面に戻る
func return_to_title() -> void:
	current_state = GameState.TITLE


# 現在の手数を取得
func get_turn_count() -> int:
	return turn_count


# 現在の山札を取得
func get_deck() -> Array[int]:
	return deck.cards


# 一番上のカードを取得
func get_top_card() -> int:
	return deck.get_top_card()


# 能力の説明テキストを取得（Configから読み込み）
func get_ability_description(card: int) -> String:
	return Config.get_ability_description(card)


# 能力名を取得（Configから読み込み）
func get_ability_name(card: int) -> String:
	return Config.get_ability_name(card)


# スキップ回数を取得
func get_skip_count() -> int:
	return skip_count


# 各カードの能力発動回数を取得
func get_ability_use_counts() -> Dictionary:
	return ability_use_counts
