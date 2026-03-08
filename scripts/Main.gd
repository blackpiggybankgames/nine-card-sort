extends Node2D

# メインシーン - ゲーム全体を統括

# デバッグモード設定（リリース時はfalseに）
@export var debug_mode: bool = true

@onready var game_manager: GameManager = $GameManager
@onready var deck_display: DeckDisplay = $DeckDisplay
@onready var ui_layer: CanvasLayer = $UILayer
@onready var background: ColorRect = $Background
@onready var title_screen: Control = $UILayer/TitleScreen
@onready var game_ui: Control = $UILayer/GameUI
@onready var clear_screen: Control = $UILayer/ClearScreen

# UI要素
@onready var turn_counter: Label = $UILayer/GameUI/TurnCounter
@onready var ability_name_label: Label = $UILayer/GameUI/AbilityName
@onready var ability_desc_label: Label = $UILayer/GameUI/AbilityDescription
@onready var use_ability_btn: Button = $UILayer/GameUI/UseAbilityButton
@onready var skip_btn: Button = $UILayer/GameUI/SkipButton
@onready var cancel_btn: Button = $UILayer/GameUI/CancelButton
@onready var instruction_label: Label = $UILayer/GameUI/InstructionLabel

# デバッグUI要素
@onready var debug_container: Control = $UILayer/GameUI/DebugContainer

# クリア画面
@onready var clear_turn_label: Label = $UILayer/ClearScreen/TurnCountLabel


func _ready() -> void:
	# 日本語フォントのテーマを適用
	var theme = load("res://assets/default_theme.tres")
	if theme:
		for child in ui_layer.get_children():
			if child is Control:
				child.theme = theme

	# 画面サイズ変更時に背景を更新
	get_viewport().size_changed.connect(_update_background_size)
	_update_background_size()

	# シグナル接続
	game_manager.turn_started.connect(_on_turn_started)
	game_manager.turn_ended.connect(_on_turn_ended)
	game_manager.target_selection_required.connect(_on_target_selection_required)
	game_manager.ability9_second_selection.connect(_on_ability9_second_selection)
	game_manager.ability9_pair_selected.connect(_on_ability9_pair_selected)
	game_manager.game_cleared.connect(_on_game_cleared)
	deck_display.card_selected.connect(_on_card_selected)

	# デバッグUIの表示設定
	_setup_debug_ui()

	# 初期状態はタイトル画面
	_show_title_screen()


# 背景サイズを画面に合わせる
func _update_background_size() -> void:
	if background:
		var viewport_size = get_viewport_rect().size
		background.size = viewport_size
		background.position = Vector2.ZERO


# デバッグUIの初期設定
func _setup_debug_ui() -> void:
	if debug_container:
		debug_container.visible = debug_mode


# タイトル画面を表示
func _show_title_screen() -> void:
	title_screen.visible = true
	game_ui.visible = false
	clear_screen.visible = false
	deck_display.visible = false


# ゲーム画面を表示
func _show_game_screen() -> void:
	title_screen.visible = false
	game_ui.visible = true
	clear_screen.visible = false
	deck_display.visible = true
	cancel_btn.visible = false
	instruction_label.visible = false


# クリア画面を表示
func _show_clear_screen(turn_count: int) -> void:
	title_screen.visible = false
	game_ui.visible = false
	clear_screen.visible = true
	deck_display.visible = true  # カードを表示してクリア状態を確認できるようにする
	deck_display.set_all_selectable(false)  # カードのクリックは無効化
	deck_display.clear_highlights()
	clear_turn_label.text = str(turn_count) + " 手でクリア！"


# ゲーム開始ボタン
func _on_start_button_pressed() -> void:
	_show_game_screen()
	deck_display.reset()  # カード表示をリセット
	game_manager.start_game()


# 手番開始時
func _on_turn_started(top_card: int) -> void:
	# 山札表示を更新
	deck_display.update_display(game_manager.get_deck())
	deck_display.highlight_top_card()
	deck_display.set_all_selectable(false)

	# UIを更新
	_update_turn_ui(top_card)
	use_ability_btn.disabled = false
	skip_btn.disabled = false
	cancel_btn.visible = false
	instruction_label.visible = false


# UIを更新
func _update_turn_ui(top_card: int) -> void:
	turn_counter.text = "手数: " + str(game_manager.get_turn_count())
	ability_name_label.text = "[" + str(top_card) + "] " + game_manager.get_ability_name(top_card)
	ability_desc_label.text = game_manager.get_ability_description(top_card)


# 手番終了時
func _on_turn_ended() -> void:
	deck_display.clear_highlights()


# 対象選択が必要な時
func _on_target_selection_required(card: int) -> void:
	use_ability_btn.disabled = true
	skip_btn.disabled = true
	cancel_btn.visible = true

	# 対象選択可能なカードをハイライト
	if card == 9:
		# 能力9: 足して9になる組み合わせを選択可能に
		deck_display.set_sum9_selectable()
		instruction_label.text = "1枚目を選んでください"
	else:
		# 能力1, 2, 3: 任意のカードを選択可能に（一番上以外）
		deck_display.set_all_selectable(true)
		var top_card = game_manager.get_top_card()
		deck_display.set_card_selectable(top_card, false)
		instruction_label.text = "移動するカードを選んでください"

	instruction_label.visible = true


# 能力9の2枚目選択時
func _on_ability9_second_selection(first_card: int) -> void:
	# 1枚目をハイライト、2枚目（ペア）のみ選択可能に
	deck_display.set_all_selectable(false)
	deck_display.set_card_selectable(first_card, false)
	deck_display.set_card_highlighted(first_card, true)

	# ペアのカード（足して9になる相手）のみ選択可能
	var pair_card = 9 - first_card
	deck_display.set_card_selectable(pair_card, true)
	deck_display.set_card_highlighted(pair_card, true)  # 2枚目もハイライト

	instruction_label.text = str(first_card) + " を選択。" + str(pair_card) + " を選んでください"


# 能力9の2枚選択完了時
func _on_ability9_pair_selected(first_card: int, second_card: int) -> void:
	# 2枚目もハイライト表示
	deck_display.set_card_highlighted(second_card, true)
	instruction_label.text = str(first_card) + " と " + str(second_card) + " を選択！"


# カードが選択された時
func _on_card_selected(card_number: int) -> void:
	if game_manager.current_state == GameManager.GameState.SELECTING_TARGET:
		game_manager.select_target(card_number)

		# 能力が実行されて状態が変わった場合のみ山札表示を更新
		# （能力9で1枚目選択中はまだSELECTING_TARGET状態なので更新しない）
		if game_manager.current_state != GameManager.GameState.SELECTING_TARGET:
			deck_display.update_display(game_manager.get_deck())


# 能力を使うボタン
func _on_use_ability_button_pressed() -> void:
	game_manager.use_ability()


# スキップボタン
func _on_skip_button_pressed() -> void:
	game_manager.skip_ability()


# キャンセルボタン
func _on_cancel_button_pressed() -> void:
	game_manager.cancel_target_selection()


# ゲームクリア時
func _on_game_cleared(turn_count: int) -> void:
	_show_clear_screen(turn_count)


# リトライボタン
func _on_retry_button_pressed() -> void:
	_show_game_screen()
	deck_display.reset()  # カード表示をリセット
	game_manager.start_game()


# タイトルに戻るボタン
func _on_title_button_pressed() -> void:
	game_manager.return_to_title()
	_show_title_screen()


# デバッグ: 即座にクリア
func _on_debug_clear_button_pressed() -> void:
	if not debug_mode:
		return
	# 山札をソート済み状態にして勝利判定を発動
	game_manager.deck.cards = [1, 2, 3, 4, 5, 6, 7, 8, 9]
	game_manager.deck.deck_changed.emit()
	# 山札表示を更新してからクリア判定
	deck_display.update_display(game_manager.get_deck())
	game_manager.deck.check_win()
