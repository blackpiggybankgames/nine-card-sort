extends Node2D

# メインシーン - ゲーム全体を統括

# デバッグモード設定（リリース時はfalseに）
@export var debug_mode: bool = true

@onready var game_manager: GameManager = $GameManager
@onready var deck_display: DeckDisplay = $DeckDisplay
@onready var ui_layer: CanvasLayer = $UILayer
@onready var background: TextureRect = $Background
@onready var title_screen: Control = $UILayer/TitleScreen
@onready var start_button: Button = $UILayer/TitleScreen/StartButton
@onready var daily_button: Button = $UILayer/TitleScreen/DailyChallengeButton
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
@onready var result_board: TextureRect = $UILayer/ClearScreen/ResultBoard
@onready var board_moves_label: Label = $UILayer/ClearScreen/BoardMovesLabel
@onready var clear_mode_label: Label = $UILayer/ClearScreen/ClearModeLabel
@onready var clear_stats_container: VBoxContainer = $UILayer/ClearScreen/StatsContainer
@onready var share_btn: Button = $UILayer/ClearScreen/ShareButton
@onready var retry_btn: Button = $UILayer/ClearScreen/RetryButton
@onready var title_btn: Button = $UILayer/ClearScreen/TitleButton
@onready var copy_toast_label: Label = $UILayer/ClearScreen/CopyToastLabel

# リザルトカード SubViewport
@onready var rc_viewport: SubViewport = $ResultCardViewport
@onready var rc_mode_label: Label = $ResultCardViewport/ResultCardScene/ModeLabel
@onready var rc_moves_label: Label = $ResultCardViewport/ResultCardScene/MovesCountLabel
@onready var rc_ability_container: VBoxContainer = $ResultCardViewport/ResultCardScene/AbilityContainer

# ステップラベル（能力発動中の説明表示）
@onready var step_label: Label = $UILayer/GameUI/StepLabel
@onready var step_label_bg: Panel = $UILayer/GameUI/StepLabelBG

# 能力発動アニメーション後にデッキ更新アニメーションをスキップするフラグ
var _skip_next_deck_update: bool = false

# クリア演出: 能力発動中にズームを先行実施済みかどうかのフラグ
var _clear_zoom_done: bool = false

# シェアパネル
var _share_panel: Control = null
var _panel_toast: Label = null


func _ready() -> void:
	# 日本語フォントのテーマを適用
	# UILayer 配下と SubViewport 内の ResultCardScene の両方に適用する
	var theme: Theme = load("res://assets/default_theme.tres")
	if theme:
		for child in ui_layer.get_children():
			if child is Control:
				child.theme = theme
		# ResultCardViewport は UILayer の外にあるためループに入らない
		var result_scene := rc_viewport.get_child(0)
		if result_scene is Control:
			result_scene.theme = theme

	# disabled 状態でもボタン画像が表示されるよう StyleBox をコード適用
	var disabled_style := StyleBoxTexture.new()
	disabled_style.texture = load("res://assets/images/buttons/btn_primary_normal.png")
	disabled_style.texture_margin_left = 24.0
	disabled_style.texture_margin_right = 24.0
	disabled_style.texture_margin_top = 18.0
	disabled_style.texture_margin_bottom = 18.0
	disabled_style.modulate_color = Color(0.55, 0.55, 0.55, 0.65)
	use_ability_btn.add_theme_stylebox_override("disabled", disabled_style)
	skip_btn.add_theme_stylebox_override("disabled", disabled_style)

	# 画面サイズ変更時に背景を更新
	get_viewport().size_changed.connect(_update_background_size)
	_update_background_size()

	# シグナル接続
	game_manager.turn_started.connect(_on_turn_started)
	game_manager.turn_ended.connect(_on_turn_ended)
	game_manager.target_selection_step_updated.connect(_on_target_selection_step_updated)
	game_manager.game_cleared.connect(_on_game_cleared)
	deck_display.card_selected.connect(_on_card_selected)
	game_manager.ability_ready.connect(_on_ability_ready)
	deck_display.insertion_point_selected.connect(_on_insertion_point_selected)

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
	board_moves_label.text = str(turn_count)
	if game_manager.is_daily_mode:
		var seed = game_manager.get_daily_seed()
		var date_str = "%d/%02d/%02d" % [seed / 10000, (seed % 10000) / 100, seed % 100]
		clear_mode_label.text = "デイリーチャレンジ（%s）" % date_str
	else:
		clear_mode_label.text = "フリーモード"
	_populate_ability_stats()


# 能力発動回数リストをクリア画面に動的生成（セピア色・クラシックフォント）
func _populate_ability_stats() -> void:
	for child in clear_stats_container.get_children():
		child.queue_free()

	var sepia := Color(0.290, 0.235, 0.157, 1)  # ダークブラウン #4a3c28

	# モード表示との区切り線
	var sep_top := HSeparator.new()
	sep_top.add_theme_color_override("color", Color(0.4, 0.25, 0.1, 0.5))
	sep_top.custom_minimum_size = Vector2(0, 6)
	clear_stats_container.add_child(sep_top)

	# スキップ回数を先頭行として追加
	var skip_row := _make_stat_row("スキップ", str(game_manager.get_skip_count()) + " 回", sepia)
	clear_stats_container.add_child(skip_row)

	# 区切り線
	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(0.4, 0.25, 0.1, 0.5))
	sep.custom_minimum_size = Vector2(0, 6)
	clear_stats_container.add_child(sep)

	var counts := game_manager.get_ability_use_counts()
	for card_num in range(1, 10):
		var label_text := "[" + str(card_num) + "] " + game_manager.get_ability_name(card_num)
		var count_text := str(counts.get(card_num, 0)) + " 回"
		var row := _make_stat_row(label_text, count_text, sepia)
		clear_stats_container.add_child(row)


func _make_stat_row(name_text: String, count_text: String, color: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label := Label.new()
	name_label.text = name_text
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", color)

	var count_label := Label.new()
	count_label.text = count_text
	count_label.custom_minimum_size = Vector2(52, 0)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.add_theme_font_size_override("font_size", 14)
	count_label.add_theme_color_override("font_color", color)

	row.add_child(name_label)
	row.add_child(count_label)
	return row


# フリープレイ開始ボタン
func _on_start_button_pressed() -> void:
	_show_game_screen()
	deck_display.reset()
	game_manager.start_game(false)


# デイリーチャレンジ開始ボタン
func _on_daily_challenge_button_pressed() -> void:
	_show_game_screen()
	deck_display.reset()
	game_manager.start_game(true)


# 手番開始時
func _on_turn_started(top_card: int) -> void:
	if _skip_next_deck_update:
		# 能力発動アニメーション済みのためデッキ更新アニメーションをスキップ
		_skip_next_deck_update = false
		deck_display.highlight_top_card()
		deck_display.set_all_selectable(false)
		deck_display.hide_insertion_arrows()
		# 短い待機後に次のカードを分離表示
		await get_tree().create_timer(0.1).timeout
		deck_display.separate_active_card()
	else:
		# 通常フロー: 山札表示を更新してアニメーション
		deck_display.update_display(game_manager.get_deck())
		deck_display.highlight_top_card()
		deck_display.set_all_selectable(false)
		deck_display.hide_insertion_arrows()
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


# 対象選択ステップ更新（全カード・全ステップ共通ハンドラ）
func _on_target_selection_step_updated(card: int, step: int, selected: Array[int]) -> void:
	use_ability_btn.disabled = true
	skip_btn.disabled = true
	cancel_btn.visible = true

	deck_display.set_all_selectable(false)
	for cn in selected:
		deck_display.set_card_highlighted(cn, true)

	match card:
		1:
			if step == 1:
				deck_display.set_all_selectable(true)
				deck_display.set_card_selectable(game_manager.get_top_card(), false)
				instruction_label.text = "入れ替えたいカードを選んでください"
			else:  # step == 2
				deck_display.set_adjacent_value_selectable(selected[0])
				instruction_label.text = str(selected[0]) + " を選択。数値±1のカードを選んでください"

		2:
			if step == 1:
				deck_display.set_all_selectable(true)
				deck_display.set_card_selectable(game_manager.get_top_card(), false)
				instruction_label.text = "回転させる3枚の1枚目を選んでください"
			else:
				deck_display.set_adjacent_extension_selectable(selected)
				instruction_label.text = str(selected.size() + 1) + "枚目を選んでください（隣のカード）"

		4:
			deck_display.set_non_edge_selectable()
			instruction_label.text = "どかすカードを選んでください（端は選択不可）"

		6:
			match step:
				1:
					deck_display.set_all_selectable(true)
					deck_display.set_card_selectable(game_manager.get_top_card(), false)
					instruction_label.text = "1組目の1枚目を選んでください"
				2:
					deck_display.set_adjacent_extension_selectable(selected)
					instruction_label.text = "1組目の2枚目を選んでください（隣のカード）"
				3:
					deck_display.set_card6_pair2_start_selectable(selected)
					instruction_label.text = "2組目の1枚目を選んでください"
				4:
					deck_display.set_card6_pair2_adjacent_selectable(selected)
					instruction_label.text = "2組目の2枚目を選んでください（隣のカード）"

		7:
			if step == 1:
				deck_display.set_block_center_any_selectable()
				instruction_label.text = "差し込む3枚ブロックの中央カードを選んでください"
			else:  # step == 2: 差し込み位置を矢印で表示
				var block_center_card = selected[0]
				var j_9 = deck_display.deck_data.find(block_center_card)
				if j_9 > 0:
					deck_display.set_card_highlighted(deck_display.deck_data[j_9 - 1], true)
				deck_display.set_card_highlighted(block_center_card, true)
				if j_9 < deck_display.deck_data.size() - 1:
					deck_display.set_card_highlighted(deck_display.deck_data[j_9 + 1], true)
				var invalid_gaps: Array = [j_9 - 1, j_9, j_9 + 1]
				var valid_gaps: Array = []
				for k in range(2, deck_display.deck_data.size()):
					if k not in invalid_gaps:
						valid_gaps.append(k)
				deck_display.show_insertion_arrows(valid_gaps)
				instruction_label.text = "差し込む場所の矢印を選んでください"

		8:
			if step == 1:
				deck_display.set_all_selectable(true)
				deck_display.set_card_selectable(game_manager.get_top_card(), false)
				instruction_label.text = "移動するカードを選んでください"
			else:  # step == 2: 挿入位置を矢印で表示
				var move_idx = deck_display.deck_data.find(selected[0])
				var valid_inserts: Array = []
				for i in range(1, deck_display.deck_data.size()):
					if i != move_idx:
						valid_inserts.append(i)
				deck_display.show_insertion_arrows(valid_inserts)
				instruction_label.text = "矢印で挿入位置を選んでください（その直前に移動）"

		9:
			if step == 1:
				deck_display.set_all_selectable(true)
				deck_display.set_card_selectable(game_manager.get_top_card(), false)
				instruction_label.text = "逆順にする4枚の1枚目を選んでください"
			else:
				deck_display.set_adjacent_extension_selectable(selected)
				instruction_label.text = str(selected.size() + 1) + "枚目を選んでください（隣のカード）"

	instruction_label.visible = true


# カードが選択された時
func _on_card_selected(card_number: int) -> void:
	if game_manager.current_state == GameManager.GameState.SELECTING_TARGET:
		game_manager.select_target(card_number)

		# 能力が実行されて状態が変わった場合のみ山札表示を更新
		if game_manager.current_state != GameManager.GameState.SELECTING_TARGET:
			deck_display.update_display(game_manager.get_deck())


# 挿入位置矢印がクリックされた時
func _on_insertion_point_selected(deck9_idx: int) -> void:
	if game_manager.current_state != GameManager.GameState.SELECTING_TARGET:
		return
	deck_display.hide_insertion_arrows()
	var card_number = deck_display.deck_data[deck9_idx]
	game_manager.select_target(card_number)
	# 能力が実行されて状態が変わった場合のみ山札表示を更新
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
	_play_clear_sequence(turn_count)


# クリア演出シーケンス（非同期）
func _play_clear_sequence(turn_count: int) -> void:
	# スキップ起因のクリアでは表示が未更新の場合があるため同期
	var gm_deck = game_manager.get_deck()
	if deck_display.deck_data != gm_deck:
		deck_display.update_display_simple(gm_deck)
		await deck_display.animation_completed

	# ズームとヒットストップ演出（能力発動中に先行実施済みの場合はスキップ）
	var zoom_was_done = _clear_zoom_done
	_clear_zoom_done = false
	if not zoom_was_done:
		await _play_clear_hit_stop()

	# クリア画面を表示（DeckDisplayはデッキが透けて見える）
	_show_clear_screen(turn_count)

	# バックグラウンドで山札を1始まりの順にソート
	await _play_clear_sort_animation()


# クリア時のズームイン・ヒットストップ演出
func _play_clear_hit_stop() -> void:
	# 最後に移動したカード（一番下）を取得
	if deck_display.deck_data.is_empty():
		return
	var last_card_num = deck_display.deck_data[-1]
	var card_node = deck_display.card_nodes.get(last_card_num)
	if not card_node or not is_instance_valid(card_node):
		return

	var viewport_size = get_viewport_rect().size
	var viewport_center = viewport_size / 2.0
	var zoom_scale = 2.0

	# ズームイン: 最後のカードを画面中央に拡大
	var card_local_pos = card_node.position
	var target_deck_pos = viewport_center - card_local_pos * zoom_scale

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(deck_display, "scale", Vector2(zoom_scale, zoom_scale), 0.35).set_ease(Tween.EASE_OUT)
	tween.tween_property(deck_display, "position", target_deck_pos, 0.35).set_ease(Tween.EASE_OUT)
	await tween.finished

	# ヒットストップ: 静止して達成感を演出
	await get_tree().create_timer(0.5).timeout


# 勝利条件を先読みチェック（Deck.is_cyclic_sorted と同じロジック）
func _will_win(deck: Array[int]) -> bool:
	for i in range(deck.size()):
		var current = deck[i]
		var next_card = deck[(i + 1) % deck.size()]
		if next_card != current % 9 + 1:
			return false
	return true


# エフェクトで最も大きく移動したカードを特定（ズームターゲット）
# eight_deck: エフェクト前の8枚、steps: アニメーションステップ配列
func _find_zoom_target_card(ability_card: int, eight_deck: Array[int], steps: Array) -> int:
	if steps.is_empty():
		# エフェクトなし（カード8表面など）: デッキ先頭カード
		return eight_deck[0] if not eight_deck.is_empty() else ability_card

	var before: Array[int] = eight_deck
	var after: Array[int] = steps[-1]["deck"]

	var max_displacement = 0
	var key_card = ability_card

	for card_num in after:
		var old_idx = before.find(card_num)
		var new_idx = after.find(card_num)
		if old_idx == -1 or new_idx == -1:
			continue
		var displacement = abs(new_idx - old_idx)
		if displacement > max_displacement:
			max_displacement = displacement
			key_card = card_num

	return key_card


# クリア確定キーカードにスポットライトズームイン（ヒットストップ含む）
func _zoom_into_key_card(card_num: int) -> void:
	var card_node = deck_display.card_nodes.get(card_num)
	if not card_node or not is_instance_valid(card_node):
		await get_tree().create_timer(0.8).timeout
		return

	var viewport_size = get_viewport_rect().size
	var viewport_center = viewport_size / 2.0
	var zoom_scale = 2.0
	# ズーム後にキーカードが画面中央に来るようDeckDisplayの位置を計算
	var card_local_pos = card_node.position
	var target_deck_pos = viewport_center - card_local_pos * zoom_scale

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(deck_display, "scale", Vector2(zoom_scale, zoom_scale), 0.35).set_ease(Tween.EASE_OUT)
	tween.tween_property(deck_display, "position", target_deck_pos, 0.35).set_ease(Tween.EASE_OUT)
	await tween.finished

	# ヒットストップ: 静止して達成感を演出
	await get_tree().create_timer(0.5).timeout


# ズームを解除しながら能力カードを底位置へ移動
func _move_ability_card_with_zoom_restore(ability_card: int, final_deck: Array[int]) -> void:
	var viewport_size = get_viewport_rect().size
	var original_deck_pos = Vector2(viewport_size.x / 2.0, viewport_size.y * 0.45)

	deck_display.deck_data = final_deck

	var tween = create_tween()
	tween.set_parallel(true)

	# DeckDisplayを元の位置・スケールに戻す
	tween.tween_property(deck_display, "scale", Vector2(1.0, 1.0), 0.5).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(deck_display, "position", original_deck_pos, 0.5).set_ease(Tween.EASE_IN_OUT)

	# 能力カードを底位置へ移動
	var card_node = deck_display.card_nodes.get(ability_card)
	if card_node and is_instance_valid(card_node):
		var new_idx = final_deck.find(ability_card)
		var target_card_pos = deck_display._get_target_position(new_idx)
		var target_card_rot = deck_display._get_target_rotation(new_idx)
		tween.tween_property(card_node, "position", target_card_pos, 0.5).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(card_node, "rotation_degrees", target_card_rot, 0.5).set_ease(Tween.EASE_IN_OUT)
		card_node.z_index = final_deck.size() - 1 - new_idx

	await tween.finished


# クリア後の山札ソートアニメーション（バックグラウンド）
func _play_clear_sort_animation() -> void:
	var viewport_size = get_viewport_rect().size
	var original_deck_pos = Vector2(viewport_size.x / 2.0, viewport_size.y * 0.45)

	# DeckDisplayを元の位置・スケールにゆっくり戻す
	var restore_tween = create_tween()
	restore_tween.set_parallel(true)
	restore_tween.tween_property(deck_display, "scale", Vector2(1.0, 1.0), 0.7).set_ease(Tween.EASE_IN_OUT)
	restore_tween.tween_property(deck_display, "position", original_deck_pos, 0.7).set_ease(Tween.EASE_IN_OUT)
	await restore_tween.finished

	# 1が先頭になるまで1枚ずつゆっくりローテーション
	var current_deck: Array[int] = deck_display.deck_data.duplicate()
	var one_idx = current_deck.find(1)
	if one_idx <= 0:
		return  # 既に1が先頭（または見つからない）

	for i in range(one_idx):
		await get_tree().create_timer(0.2).timeout
		var top = current_deck.pop_front()
		current_deck.push_back(top)
		deck_display.update_display_with_duration(current_deck, 0.5)
		await deck_display.animation_completed


# シェアボタン: シェアパネルを表示する
func _on_share_button_pressed() -> void:
	if _share_panel == null:
		_create_share_panel()
	_share_panel.visible = true


# シェアパネルをGDScriptで動的生成してUILayerに追加する
func _create_share_panel() -> void:
	# フルスクリーンコンテナ（非表示）
	_share_panel = Control.new()
	_share_panel.name = "SharePanel"
	_share_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_share_panel.visible = false
	ui_layer.add_child(_share_panel)

	# 半透明黒オーバーレイ（背景UIの操作をブロック）
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.0, 0.70)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_share_panel.add_child(overlay)

	# パネルコンテナ（画面中央）
	var viewport_size: Vector2 = get_viewport_rect().size
	var board_w := 350.0
	var board_h := 500.0
	var panel_container := Control.new()
	panel_container.position = Vector2(
		(viewport_size.x - board_w) * 0.5,
		(viewport_size.y - board_h) * 0.5
	)
	panel_container.size = Vector2(board_w, board_h)
	_share_panel.add_child(panel_container)

	# 黒背景を透過させるシェーダー（COLOR = col で暗転を防ぐ）
	var black_mat: ShaderMaterial = ShaderMaterial.new()
	black_mat.shader = load("res://assets/shaders/black_transparent.gdshader") as Shader

	# ボード背景画像（share_panel_board.png）
	var board_tex := TextureRect.new()
	board_tex.texture = load("res://assets/images/result/share_panel_board.png")
	board_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	board_tex.stretch_mode = TextureRect.STRETCH_SCALE
	board_tex.size = Vector2(board_w, board_h)
	board_tex.mouse_filter = Control.MOUSE_FILTER_PASS
	board_tex.material = black_mat
	panel_container.add_child(board_tex)

	# ×閉じるボタン（右上）
	var close_tex := load("res://assets/images/buttons/close_button_x.png")
	var close_btn := TextureButton.new()
	close_btn.texture_normal = close_tex
	close_btn.ignore_texture_size = true
	close_btn.stretch_mode = TextureButton.STRETCH_SCALE
	close_btn.position = Vector2(board_w - 50.0, 6.0)
	close_btn.size = Vector2(44.0, 44.0)
	close_btn.pressed.connect(_on_share_panel_close)
	close_btn.material = black_mat
	panel_container.add_child(close_btn)

	# ボタン3つを縦に並べる
	var btn_w := 280.0
	var btn_h := 70.0
	var btn_spacing := 20.0
	var btn_x := (board_w - btn_w) * 0.5
	var btn_y_start := 170.0

	var copy_btn := _make_gold_button(panel_container, "テキストをコピー", Vector2(btn_x, btn_y_start), Vector2(btn_w, btn_h), black_mat)
	copy_btn.pressed.connect(_on_share_panel_copy_text)

	var save_btn := _make_gold_button(panel_container, "画像を保存", Vector2(btn_x, btn_y_start + (btn_h + btn_spacing)), Vector2(btn_w, btn_h), black_mat)
	save_btn.pressed.connect(_on_share_panel_save_image)

	var survey_btn := _make_gold_button(panel_container, "アンケートに答える", Vector2(btn_x, btn_y_start + (btn_h + btn_spacing) * 2.0), Vector2(btn_w, btn_h), black_mat)
	survey_btn.pressed.connect(_on_share_panel_survey)

	# Toastラベル（操作完了メッセージ）
	_panel_toast = Label.new()
	_panel_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel_toast.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_panel_toast.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))
	_panel_toast.add_theme_font_size_override("font_size", 14)
	_panel_toast.size = Vector2(board_w, 30.0)
	_panel_toast.position = Vector2(0.0, 140.0)
	_panel_toast.visible = false
	panel_container.add_child(_panel_toast)


# TextureButton（テクスチャ切り替えでホバー/プレスを表現）+ Label（テキスト）方式
# TextureButtonにシェーダーを適用し、Labelは別ノードでフォントカラーを正しく保持する
func _make_gold_button(parent: Control, label_text: String, pos: Vector2, sz: Vector2, black_mat: ShaderMaterial) -> TextureButton:
	var container := Control.new()
	container.position = pos
	container.size = sz
	parent.add_child(container)

	# TextureButton: テクスチャ切り替えでホバー/プレスを表現（頂点カラー干渉なし）
	# focus_mode=NONE でクリック後もホバーが正常に反応する
	var tbtn := TextureButton.new()
	tbtn.texture_normal = load("res://assets/images/buttons/btn_primary_normal.png") as Texture2D
	tbtn.texture_hover = load("res://assets/images/buttons/btn_primary_hover.png") as Texture2D
	tbtn.texture_pressed = load("res://assets/images/buttons/btn_primary_pressed.png") as Texture2D
	tbtn.ignore_texture_size = true
	tbtn.stretch_mode = TextureButton.STRETCH_SCALE
	tbtn.size = sz
	tbtn.focus_mode = Control.FOCUS_NONE
	tbtn.material = black_mat
	container.add_child(tbtn)

	# Label: シェーダーなし・クリック透過・フォントカラーを正しく描画
	var lbl := Label.new()
	lbl.text = label_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.size = sz
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	lbl.add_theme_font_override("font", load("res://assets/fonts/ShipporiMincho-ExtraBold.ttf") as Font)
	lbl.add_theme_font_size_override("font_size", 18)
	container.add_child(lbl)

	return tbtn


# ×ボタン: パネルを閉じる
func _on_share_panel_close() -> void:
	if _share_panel != null:
		_share_panel.visible = false


# テキストコピーボタン
func _on_share_panel_copy_text() -> void:
	DisplayServer.clipboard_set(_generate_share_text())
	_show_panel_toast("テキストをコピーしました！")


# 画像保存ボタン
func _on_share_panel_save_image() -> void:
	await _save_screenshot()
	_show_panel_toast("画像を保存しました！")


# アンケートボタン: survey_url をブラウザで開く
func _on_share_panel_survey() -> void:
	var url := Config.get_survey_url(debug_mode)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.open('" + url + "', '_blank')")
	else:
		OS.shell_open(url)


# パネル内Toastラベルを2秒表示する
func _show_panel_toast(msg: String) -> void:
	if _panel_toast == null:
		return
	_panel_toast.text = msg
	_panel_toast.visible = true
	await get_tree().create_timer(2.0).timeout
	_panel_toast.visible = false


# SNS連携テキストを生成（140字以内）
func _generate_share_text() -> String:
	var url = Config.get_share_url(debug_mode)
	var hashtag = Config.get_share_hashtag()
	var turn_count = game_manager.get_turn_count()

	if game_manager.is_daily_mode:
		var seed = game_manager.get_daily_seed()
		var date_str = "%d/%02d/%02d" % [seed / 10000, (seed % 10000) / 100, seed % 100]
		return "Nine Card Sort デイリーチャレンジ（%s）をクリア！\n%d手でクリア\n%s\n%s" % [date_str, turn_count, hashtag, url]
	else:
		return "Nine Card Sort をクリア！\n%d手でクリア\n%s\n%s" % [turn_count, hashtag, url]


# リザルトカードの動的コンテンツを SubViewport に書き込む
func _update_result_card() -> void:
	var turn_count = game_manager.get_turn_count()
	var skip_count = game_manager.get_skip_count()

	if game_manager.is_daily_mode:
		var seed = game_manager.get_daily_seed()
		var date_str = "%d/%02d/%02d" % [seed / 10000, (seed % 10000) / 100, seed % 100]
		rc_mode_label.text = "デイリーチャレンジ（%s）" % date_str
	else:
		rc_mode_label.text = "フリーモード"

	rc_moves_label.text = str(turn_count)

	# クリア画面と同じ構成で再構築
	for child in rc_ability_container.get_children():
		child.queue_free()

	var sepia := Color(0.290, 0.235, 0.157, 1)

	var sep_top := HSeparator.new()
	sep_top.add_theme_color_override("color", Color(0.4, 0.25, 0.1, 0.5))
	sep_top.custom_minimum_size = Vector2(0, 6)
	rc_ability_container.add_child(sep_top)

	var skip_row := _make_stat_row("スキップ", str(skip_count) + " 回", sepia)
	rc_ability_container.add_child(skip_row)

	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(0.4, 0.25, 0.1, 0.5))
	sep.custom_minimum_size = Vector2(0, 6)
	rc_ability_container.add_child(sep)

	var counts = game_manager.get_ability_use_counts()
	for i in range(1, 10):
		var ability_name = game_manager.get_ability_name(i)
		var count = counts.get(i, 0)
		var row := _make_stat_row("[%d] %s" % [i, ability_name], str(count) + " 回", sepia)
		rc_ability_container.add_child(row)


# リザルトカードを SubViewport でレンダリングしてダウンロード
# Web: PNG→Base64→data URLでJSダウンロード / ネイティブ: PNGファイル保存
func _save_screenshot() -> void:
	_update_result_card()
	# queue_free完了 + SubViewport描画確定のため2フレーム待機
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := rc_viewport.get_texture().get_image()
	if image == null or image.is_empty():
		return
	if OS.has_feature("web"):
		var png_bytes := image.save_png_to_buffer()
		var base64_data := Marshalls.raw_to_base64(png_bytes)
		JavaScriptBridge.eval(_build_download_js(base64_data))
	else:
		image.save_png("user://nine-card-sort-result.png")


# Base64エンコードした PNG を data URL でダウンロードする JS スニペット
func _build_download_js(base64_data: String) -> String:
	return """(function() {
	var a = document.createElement('a');
	a.href = 'data:image/png;base64,""" + base64_data + """';
	a.download = 'nine-card-sort-result.png';
	document.body.appendChild(a);
	a.click();
	document.body.removeChild(a);
})();"""


# リトライボタン（前回と同じモードで再開）
func _on_retry_button_pressed() -> void:
	_show_game_screen()
	deck_display.reset()
	game_manager.start_game(game_manager.is_daily_mode)


# タイトルに戻るボタン
func _on_title_button_pressed() -> void:
	game_manager.return_to_title()
	_show_title_screen()


# ===== 能力発動アニメーション =====

# ability_readyシグナルで呼ばれる: アニメーション再生後に実際の処理を実行
func _on_ability_ready(card: int, target1: int, target2: int, ability_card: int) -> void:
	# ボタンを無効化（アニメーション中は操作不可）
	use_ability_btn.disabled = true
	skip_btn.disabled = true
	cancel_btn.visible = false
	instruction_label.visible = false

	# カード選択エフェクトをクリア（能力発動前に選択可能表示を消す）
	deck_display.set_all_selectable(false)
	deck_display.clear_highlights()

	# 分離アニメーション等が終わるまで待機
	if deck_display.is_animating:
		await deck_display.animation_completed

	# 発動カードを除いた8枚のデッキを取得
	var eight_deck: Array[int] = game_manager.get_deck().duplicate()
	eight_deck.erase(ability_card)

	# アニメーションステップを計算（副作用なし）
	var steps: Array = _compute_animation_steps(card, target1, target2, eight_deck)

	# 能力名を表示
	_show_step_label("【" + game_manager.get_ability_name(card) + "】")
	await get_tree().create_timer(0.5).timeout

	# 各ステップをアニメーション
	for step in steps:
		_show_step_label(step["label"])
		var step_deck: Array[int] = step["deck"]
		deck_display.update_display(step_deck)
		await deck_display.animation_completed
		await get_tree().create_timer(0.3).timeout

	# 発動カードを一番下へ移動するアニメーション
	var base_deck: Array[int]
	if steps.is_empty():
		base_deck = eight_deck
	else:
		base_deck = steps[-1]["deck"]
	var final_deck: Array[int] = base_deck.duplicate()
	final_deck.push_back(ability_card)
	_show_step_label("発動カードを一番下へ移動")

	# 勝利判定の先読み: クリア確定ならキーカードにズームしてから能力カードを底へ
	if _will_win(final_deck):
		_hide_step_label()
		var key_card = _find_zoom_target_card(ability_card, eight_deck, steps)
		await _zoom_into_key_card(key_card)
		await _move_ability_card_with_zoom_restore(ability_card, final_deck)
		_clear_zoom_done = true
	else:
		deck_display.update_display_simple(final_deck)  # 一直線アニメーション（スキップと同じ軌道）
		await deck_display.animation_completed
		await get_tree().create_timer(0.2).timeout
		_hide_step_label()

	# 表示が最終状態なので次のデッキ更新アニメーションをスキップ
	_skip_next_deck_update = true

	# 実際のゲームロジックを実行（表示は既に最終状態）
	game_manager.commit_ability_execution(card, target1, target2, ability_card)


# 能力の視覚アニメーションステップを計算する（デッキのコピーで計算、副作用なし）
# eight_deck: 発動カードを除いた8枚のデッキ
# 戻り値: {deck: Array[int], label: String} の配列
func _compute_animation_steps(card: int, target1: int, target2: int, eight_deck: Array[int]) -> Array:
	var steps: Array = []
	var d: Array[int] = eight_deck.duplicate()

	match card:
		1:  # ±1入れ替え
			var idx1 = d.find(target1)
			var idx2 = d.find(target2)
			if idx1 != -1 and idx2 != -1:
				d[idx1] = target2
				d[idx2] = target1
				steps.append({"deck": d.duplicate(), "label": str(target1) + " と " + str(target2) + " の位置を入れ替え"})

		2:  # 3枚順繰り
			var idx = d.find(target1)
			if idx != -1 and idx <= d.size() - 3:
				var a = d[idx]
				var b = d[idx + 1]
				var c = d[idx + 2]
				d[idx] = b
				d[idx + 1] = c
				d[idx + 2] = a
				steps.append({"deck": d.duplicate(), "label": str(a) + " を右端へ移動"})

		3:  # 全体リバース
			d.reverse()
			steps.append({"deck": d.duplicate(), "label": "全体の順序を逆転"})

		4:  # どかす（2ステップ）
			var idx = d.find(target1)
			if idx != -1 and idx > 0 and idx < d.size() - 1:
				# ステップ1: 両隣を入れ替え
				var left = d[idx - 1]
				var right = d[idx + 1]
				d[idx - 1] = right
				d[idx + 1] = left
				steps.append({"deck": d.duplicate(), "label": str(left) + " と " + str(right) + " の位置を入れ替え"})
				# ステップ2: 選択カードを一番下へ
				var selected = d[idx]
				d.remove_at(idx)
				d.push_back(selected)
				steps.append({"deck": d.duplicate(), "label": str(selected) + " を一番下へ移動"})

		5:  # 上下入れ替え
			var top4 = [d[0], d[1], d[2], d[3]]
			var bot4 = [d[4], d[5], d[6], d[7]]
			d[0] = bot4[0]; d[1] = bot4[1]; d[2] = bot4[2]; d[3] = bot4[3]
			d[4] = top4[0]; d[5] = top4[1]; d[6] = top4[2]; d[7] = top4[3]
			steps.append({"deck": d.duplicate(), "label": "上4枚と下4枚を入れ替え"})

		6:  # 2セット下送り（2ステップ）
			var idx1 = d.find(target1)
			var idx2 = d.find(target2)
			var first_top = target1 if idx1 < idx2 else target2
			var second_top = target2 if idx1 < idx2 else target1
			# ステップ1: 1組目を一番下へ
			var fi = d.find(first_top)
			var fc1 = d[fi]
			var fc2 = d[fi + 1]
			d.remove_at(fi + 1)
			d.remove_at(fi)
			d.push_back(fc1)
			d.push_back(fc2)
			steps.append({"deck": d.duplicate(), "label": str(fc1) + "・" + str(fc2) + " を一番下へ"})
			# ステップ2: 2組目を一番下へ
			var si = d.find(second_top)
			var sc1 = d[si]
			var sc2 = d[si + 1]
			d.remove_at(si + 1)
			d.remove_at(si)
			d.push_back(sc1)
			d.push_back(sc2)
			steps.append({"deck": d.duplicate(), "label": str(sc1) + "・" + str(sc2) + " も一番下へ"})

		7:  # 3枚ブロック差し込み
			# target1 = block_center_card, target2 = gap_right_card（選択順変更後）
			var i = d.find(target2)   # ギャップ右側
			var j = d.find(target1)   # ブロック中央
			if i != -1 and j != -1 and j > 0 and j < d.size() - 1:
				var bl = d[j - 1]
				var bc = d[j]
				var br = d[j + 1]
				# 高インデックスから削除（位置ずれ防止）
				d.remove_at(j + 1)
				d.remove_at(j)
				d.remove_at(j - 1)
				# ギャップ右側カード（target2）の新インデックスを取得（除去後にずれる）
				# ※target1（ブロック中央）は除去済みなので target2 で検索する
				var new_i = d.find(target2)
				if new_i == -1:
					# 本来UIで防止済みだが万が一の場合はブロックを元に戻す
					d.insert(j - 1, bl)
					d.insert(j, bc)
					d.insert(j + 1, br)
				else:
					d.insert(new_i, br)
					d.insert(new_i, bc)
					d.insert(new_i, bl)
					steps.append({"deck": d.duplicate(), "label": str(bl) + "・" + str(bc) + "・" + str(br) + " を差し込み"})

		8:  # 上下反転＋任意移動
			if target1 != -1:  # 裏面: カード移動
				var move_idx = d.find(target1)
				if move_idx != -1:
					d.remove_at(move_idx)
					var insert_idx = d.find(target2)
					d.insert(insert_idx, target1)
					steps.append({"deck": d.duplicate(), "label": str(target1) + " を " + str(target2) + " の前へ移動"})
			# 表面（target1 == -1）: カード移動なし、ステップなし

		9:  # 4枚逆順（target1 = 4枚グループの先頭カード）
			var j = d.find(target1)
			if j != -1 and j + 3 < d.size():
				var c0 = d[j]
				var c1 = d[j + 1]
				var c2 = d[j + 2]
				var c3 = d[j + 3]
				d[j] = c3
				d[j + 1] = c2
				d[j + 2] = c1
				d[j + 3] = c0
				steps.append({"deck": d.duplicate(), "label": str(c0) + "・" + str(c1) + "・" + str(c2) + "・" + str(c3) + " を逆順に"})

	return steps


func _show_step_label(text: String) -> void:
	step_label.text = text
	step_label.visible = true
	step_label_bg.visible = true


func _hide_step_label() -> void:
	step_label.visible = false
	step_label_bg.visible = false


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
