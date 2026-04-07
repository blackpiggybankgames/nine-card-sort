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
	game_manager.target_selection_step2_required.connect(_on_target_selection_step2_required)
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

	# 発動カード（一番上）を山札から分離して表示
	# 少し待ってからアニメーション開始（山札の移動アニメーションが終わってから）
	await get_tree().create_timer(deck_display.animation_duration + 0.05).timeout
	deck_display.separate_active_card()

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
	deck_display.reset_separation()  # 発動カードの分離状態をリセット


# 対象選択が必要な時（1段階目）
func _on_target_selection_required(card: int) -> void:
	use_ability_btn.disabled = true
	skip_btn.disabled = true
	cancel_btn.visible = true

	match card:
		1:  # ±1入れ替え: ソースカードを選択（任意の1枚）
			deck_display.set_all_selectable(true)
			deck_display.set_card_selectable(game_manager.get_top_card(), false)
			instruction_label.text = "入れ替えたいカードを選んでください"
		2:  # 3枚順繰り: 3枚グループの先頭を選択
			deck_display.set_trio_top_selectable()
			instruction_label.text = "3枚グループの先頭（上側）カードを選んでください"
		4:  # どかす: 端以外のカードを選択
			deck_display.set_non_edge_selectable()
			instruction_label.text = "どかすカードを選んでください（端は選択不可）"
		6:  # 2セット下送り: 1組目のペアトップを選択
			deck_display.set_pair_top_selectable()
			instruction_label.text = "1組目のペアの上側カードを選んでください"
		7:  # 3枚ブロック差し込み: ギャップ右側カードを選択
			deck_display.set_gap_right_selectable()
			instruction_label.text = "差し込み先（このカードの直前）を選んでください"
		8:  # 上下反転裏面: 移動するカードを選択
			deck_display.set_all_selectable(true)
			deck_display.set_card_selectable(game_manager.get_top_card(), false)
			instruction_label.text = "移動するカードを選んでください"
		9:  # 4枚逆順: ペアトップカードを選択
			deck_display.set_four_reverse_pair_selectable()
			instruction_label.text = "逆順にする4枚の中央2枚の上側を選んでください"

	instruction_label.visible = true


# 2段階選択の2段階目
func _on_target_selection_step2_required(card: int, first_target: int) -> void:
	deck_display.set_all_selectable(false)
	deck_display.set_card_highlighted(first_target, true)

	match card:
		1:  # ±1入れ替え: ±1の数値のカードを選択
			deck_display.set_adjacent_value_selectable(first_target)
			instruction_label.text = str(first_target) + " を選択。数値±1のカードを選んでください"
		6:  # 2セット下送り: 2組目のペアトップを選択（1組目と重複不可）
			# 1組目のペアをハイライト
			var partner_idx = game_manager.get_deck().find(first_target) + 1
			if partner_idx < game_manager.get_deck().size():
				deck_display.set_card_highlighted(game_manager.get_deck()[partner_idx], true)
			deck_display.set_pair_top_selectable_excluding(first_target)
			instruction_label.text = "2組目のペアの上側カードを選んでください"
		7:  # 3枚ブロック差し込み: ブロック中央カードを選択
			deck_display.set_block_center_selectable(first_target)
			instruction_label.text = "差し込む3枚ブロックの中央カードを選んでください（差し込み先の隣は不可）"
		8:  # 任意移動裏面: 挿入位置カードを選択（このカードの直前に移動）
			deck_display.set_insertion_target_selectable(first_target)
			instruction_label.text = "このカードの直前に移動します。挿入位置を選んでください"


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
