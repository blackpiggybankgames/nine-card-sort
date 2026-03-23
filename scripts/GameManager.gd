extends Node
class_name GameManager

# ゲーム全体の状態と手番を管理するクラス

signal turn_started(top_card: int)      # 手番開始時
signal turn_ended                        # 手番終了時
signal ability_used(card: int)           # 能力使用時
signal target_selection_required(card: int)  # 対象選択が必要な時
signal ability9_second_selection(first_card: int)  # 能力9で2枚目選択が必要な時
signal ability9_pair_selected(first_card: int, second_card: int)  # 能力9で2枚選択完了時
signal game_cleared(turn_count: int)     # ゲームクリア時

# ゲームの状態
enum GameState {
	TITLE,           # タイトル画面
	PLAYING,         # プレイ中
	SELECTING_TARGET, # 対象選択中
	CLEARED          # クリア
}

var current_state: GameState = GameState.TITLE
var turn_count: int = 0
var deck: Deck

# 対象選択中の情報
var selecting_ability: int = -1  # 現在選択中の能力
var selected_targets: Array[int] = []  # 選択済みの対象


func _ready() -> void:
	# Deckノードを取得（子ノードとして追加されている前提）
	deck = Deck.new()
	add_child(deck)

	# シグナル接続
	deck.game_won.connect(_on_game_won)


# ゲームを開始する
func start_game() -> void:
	current_state = GameState.PLAYING
	turn_count = 0
	deck.shuffle_deck()
	_start_turn()


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
		# 対象選択不要な能力はそのまま発動
		# 能力発動前のカード（手番開始時の一番上）を記憶
		_execute_ability(top_card, -1, -1, top_card)


# 対象選択が必要な能力かどうか
func _requires_target_selection(card: int) -> bool:
	# 1, 2: 任意の1枚を選択
	# 3: 端以外の1枚を選択（両隣入替用）
	# 9: 足して9になる2枚を選択
	return card in [1, 2, 3, 9]


# 対象を選択する（UI側から呼ばれる）
func select_target(card_number: int) -> void:
	if current_state != GameState.SELECTING_TARGET:
		return

	# 能力9は2枚選択が必要（足して9になる組み合わせ）
	if selecting_ability == 9:
		if card_number not in selected_targets:
			selected_targets.append(card_number)

		# 1枚目を選択したら、2枚目（ペア）のみ選択可能に
		if selected_targets.size() == 1:
			ability9_second_selection.emit(selected_targets[0])

		# 2枚選択されたら発動
		elif selected_targets.size() == 2:
			var card1 = selected_targets[0]
			var card2 = selected_targets[1]

			# 足して9になるかチェック（UIで制限しているので基本的に成功）
			if card1 + card2 == 9:
				# 2枚選択完了のシグナルを発火（UIでハイライト表示用）
				ability9_pair_selected.emit(card1, card2)
				# selecting_abilityが手番開始時の一番上のカード
				_execute_ability(selecting_ability, card1, card2, selecting_ability)
			else:
				# 無効な組み合わせ - 選択をリセット
				selected_targets.clear()
				target_selection_required.emit(selecting_ability)
	else:
		# 1枚選択の能力
		# selecting_abilityが手番開始時の一番上のカード
		_execute_ability(selecting_ability, card_number, -1, selecting_ability)


# 対象選択をキャンセルする
func cancel_target_selection() -> void:
	if current_state != GameState.SELECTING_TARGET:
		return

	current_state = GameState.PLAYING
	selecting_ability = -1
	selected_targets.clear()
	_start_turn()


# 能力を実行する
# original_top_card: 手番開始時に一番上だったカード（能力発動カード）
func _execute_ability(card: int, target1: int = -1, target2: int = -1, original_top_card: int = -1) -> void:
	# 能力発動カードを山札から取り除く（能力の効果対象にならないようにする）
	var ability_card = original_top_card if original_top_card != -1 else card
	deck.remove_card(ability_card)

	# 能力を実行（発動カードがない状態で）
	var success = deck.use_ability(card, target1, target2)

	if success:
		ability_used.emit(card)
		turn_count += 1

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
