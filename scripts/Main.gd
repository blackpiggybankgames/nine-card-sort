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


func _ready() -> void:
	# 日本語フォントのテーマを適用
	# UILayer 配下と SubViewport 内の ResultCardScene の両方に適用する
	var theme = load("res://assets/default_theme.tres")
	if theme:
		for child in ui_layer.get_children():
			if child is Control:
				child.theme = theme
		# ResultCardViewport は UILayer の外にあるためループに入らない
		var result_scene := rc_viewport.get_child(0)
		if result_scene is Control:
			result_scene.theme = theme

	# 画面サイズ変更時に背景を更新
	get_viewport().size_changed.connect(_update_background_size)
	_update_background_size()

	# 画面サイズ変更時にレイアウトを再適用（回転対応）
	get_viewport().size_changed.connect(_setup_responsive_layout)

	# シグナル接続
	game_manager.turn_started.connect(_on_turn_started)
	game_manager.turn_ended.connect(_on_turn_ended)
	game_manager.target_selection_required.connect(_on_target_selection_required)
	game_manager.target_selection_step2_required.connect(_on_target_selection_step2_required)
	game_manager.game_cleared.connect(_on_game_cleared)
	deck_display.card_selected.connect(_on_card_selected)
	game_manager.ability_ready.connect(_on_ability_ready)
	deck_display.insertion_point_selected.connect(_on_insertion_point_selected)

	# デバッグUIの表示設定
	_setup_debug_ui()

	# 初期状態はタイトル画面
	_show_title_screen()

	# 起動時にレイアウトを適用
	_setup_responsive_layout()


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
		7:  # 3枚ブロック差し込み: まず差し込むブロックの中央カードを選択
			deck_display.set_block_center_any_selectable()
			instruction_label.text = "差し込む3枚ブロックの中央カードを選んでください"
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
		7:  # 3枚ブロック差し込み: ブロック中央選択後、有効な差し込み位置を矢印で表示
			# first_target = block_center_card（ステップ1で選んだカード）
			var block_center_card = first_target
			var j_9 = deck_display.deck_data.find(block_center_card)
			# ブロック3枚をハイライト
			if j_9 > 0:
				deck_display.set_card_highlighted(deck_display.deck_data[j_9 - 1], true)
			deck_display.set_card_highlighted(block_center_card, true)
			if j_9 < deck_display.deck_data.size() - 1:
				deck_display.set_card_highlighted(deck_display.deck_data[j_9 + 1], true)
			# ブロック3枚と重なる位置を除外して矢印を表示
			# 無効な矢印の9-card index: j_9-1, j_9, j_9+1
			var invalid_gaps: Array = [j_9 - 1, j_9, j_9 + 1]
			var valid_gaps: Array = []
			for k in range(2, deck_display.deck_data.size()):
				if k not in invalid_gaps:
					valid_gaps.append(k)
			deck_display.show_insertion_arrows(valid_gaps)
			instruction_label.text = "差し込む場所の矢印を選んでください"
		8:  # 任意移動裏面: 挿入位置を矢印で選択（card_to_move の位置を除く）
			var move_idx = deck_display.deck_data.find(first_target)
			var valid_inserts: Array = []
			for i in range(1, deck_display.deck_data.size()):
				if i != move_idx:
					valid_inserts.append(i)
			deck_display.show_insertion_arrows(valid_inserts)
			instruction_label.text = "矢印で挿入位置を選んでください（その直前に移動）"


# カードが選択された時
func _on_card_selected(card_number: int) -> void:
	if game_manager.current_state == GameManager.GameState.SELECTING_TARGET:
		game_manager.select_target(card_number)

		# 能力が実行されて状態が変わった場合のみ山札表示を更新
		# （能力9で1枚目選択中はまだSELECTING_TARGET状態なので更新しない）
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


# シェアボタン: スクリーンショット保存 + SNSテキストをクリップボードにコピー
func _on_share_button_pressed() -> void:
	share_btn.disabled = true
	await _save_screenshot()
	DisplayServer.clipboard_set(_generate_share_text())
	copy_toast_label.visible = true
	await get_tree().create_timer(2.0).timeout
	copy_toast_label.visible = false
	share_btn.disabled = false


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

		9:  # 4枚逆順
			var j = d.find(target1)
			if j != -1 and j > 0 and j + 2 < d.size():
				var c0 = d[j - 1]
				var c1 = d[j]
				var c2 = d[j + 1]
				var c3 = d[j + 2]
				d[j - 1] = c3
				d[j] = c2
				d[j + 1] = c1
				d[j + 2] = c0
				steps.append({"deck": d.duplicate(), "label": str(c0) + "・" + str(c1) + "・" + str(c2) + "・" + str(c3) + " を逆順に"})

	return steps


func _show_step_label(text: String) -> void:
	step_label.text = text
	step_label.visible = true
	step_label_bg.visible = true


func _hide_step_label() -> void:
	step_label.visible = false
	step_label_bg.visible = false


# ===== レスポンシブレイアウト =====

# portrait（縦長）判定: スマホ縦向き時に true
# 幅600px以上（iPad等タブレット）はlandscape扱いにする
func _is_portrait() -> bool:
	var vp := get_viewport().size
	return vp.y > vp.x and vp.x < 600


# 画面向きに応じてレイアウトを切り替えるエントリポイント
func _setup_responsive_layout() -> void:
	if _is_portrait():
		_apply_portrait_layout()
	else:
		_apply_landscape_layout()


# portrait 時のレイアウト適用
func _apply_portrait_layout() -> void:
	# UILayer CanvasLayer は論理仮想座標空間（幅800基準）で描画される
	# portrait 時は幅が制約になるため、論理高さ = device_h × base_w / device_w
	# DPR は分子・分母に同じく掛かるため自然に相殺される
	var vp_h: float = float(get_viewport().size.y) * 800.0 / float(get_viewport().size.x)
	var center_y: float = vp_h / 2.0

	# タイトルボタン: 幅560px・高さ160px、ペアを中央に配置（gap 20px）
	var btn_top = center_y - 170.0
	start_button.offset_left = -280.0
	start_button.offset_right = 280.0
	start_button.offset_top = btn_top
	start_button.offset_bottom = btn_top + 160.0
	start_button.add_theme_font_size_override("font_size", 36)
	daily_button.offset_left = -280.0
	daily_button.offset_right = 280.0
	daily_button.offset_top = btn_top + 180.0
	daily_button.offset_bottom = btn_top + 340.0
	daily_button.add_theme_font_size_override("font_size", 36)

	# ゲームボタン: 横並び・幅240px・高さ180px
	use_ability_btn.offset_left = -250.0
	use_ability_btn.offset_right = -10.0
	use_ability_btn.offset_top = -200.0
	use_ability_btn.offset_bottom = -20.0
	use_ability_btn.add_theme_font_size_override("font_size", 32)
	skip_btn.offset_left = 10.0
	skip_btn.offset_right = 250.0
	skip_btn.offset_top = -200.0
	skip_btn.offset_bottom = -20.0
	skip_btn.add_theme_font_size_override("font_size", 32)

	# クリア画面ボタン: 縦1列・幅560px・高さ160px、画面下部に配置（gap 20px）
	# カード表示(y≈700〜900)と重ならないよう画面下部から配置
	var cb_top = vp_h - 540.0  # 3×160 + 2×20 = 520px、下マージン20px
	share_btn.offset_left = -280.0
	share_btn.offset_right = 280.0
	share_btn.offset_top = cb_top
	share_btn.offset_bottom = cb_top + 160.0
	share_btn.add_theme_font_size_override("font_size", 32)
	retry_btn.offset_left = -280.0
	retry_btn.offset_right = 280.0
	retry_btn.offset_top = cb_top + 180.0
	retry_btn.offset_bottom = cb_top + 340.0
	retry_btn.add_theme_font_size_override("font_size", 32)
	title_btn.offset_left = -280.0
	title_btn.offset_right = 280.0
	title_btn.offset_top = cb_top + 360.0
	title_btn.offset_bottom = cb_top + 520.0
	title_btn.add_theme_font_size_override("font_size", 32)

	# クリア画面リザルトボード: カード位置(y=vp_h×0.45)に中央合わせ、ボタン上端まで最大化
	# 元ボードサイズ: 幅339px・高さ506px（top=7, bottom=513）
	var card_y: float = vp_h * 0.45
	var _half_a: float = card_y - 15.0
	var _half_b: float = cb_top - 20.0 - card_y
	var board_half_h: float = _half_a if _half_a <= _half_b else _half_b
	var board_h: float = board_half_h * 2.0
	var board_top: float = card_y - board_half_h
	var sf: float = board_h / 506.0  # 元ボード高さ(506px)に対するスケール係数

	result_board.offset_left = -169.5 * sf
	result_board.offset_right = 169.5 * sf
	result_board.offset_top = board_top
	result_board.offset_bottom = board_top + board_h

	# BoardMovesLabel（元: top=29, bottom=65, left=-7, right=48）
	board_moves_label.offset_left = -7.0 * sf
	board_moves_label.offset_right = 48.0 * sf
	board_moves_label.offset_top = board_top + 22.0 * sf
	board_moves_label.offset_bottom = board_top + 58.0 * sf
	var moves_font_size: int = int(26.0 * sf)
	board_moves_label.add_theme_font_size_override("font_size", moves_font_size)

	# ClearModeLabel（元: top=111, bottom=127, left=-123, right=123）
	clear_mode_label.offset_left = -123.0 * sf
	clear_mode_label.offset_right = 123.0 * sf
	clear_mode_label.offset_top = board_top + 104.0 * sf
	clear_mode_label.offset_bottom = board_top + 120.0 * sf
	var mode_font_size: int = int(14.0 * sf)
	clear_mode_label.add_theme_font_size_override("font_size", mode_font_size)

	# StatsContainer（元: top=130.5, bottom=491.5, left=-123, right=123）
	clear_stats_container.offset_left = -123.0 * sf
	clear_stats_container.offset_right = 123.0 * sf
	clear_stats_container.offset_top = board_top + 123.5 * sf
	clear_stats_container.offset_bottom = board_top + 484.5 * sf


# landscape 時のレイアウト適用（PC・横向き: 元の値に戻す）
func _apply_landscape_layout() -> void:
	# タイトルボタンを元の値に戻す
	start_button.offset_left = -100.0
	start_button.offset_right = 100.0
	start_button.offset_top = 320.0
	start_button.offset_bottom = 370.0
	start_button.remove_theme_font_size_override("font_size")
	daily_button.offset_left = -100.0
	daily_button.offset_right = 100.0
	daily_button.offset_top = 385.0
	daily_button.offset_bottom = 435.0
	daily_button.remove_theme_font_size_override("font_size")

	# ゲームボタンを元の値に戻す
	use_ability_btn.offset_left = -180.0
	use_ability_btn.offset_right = -20.0
	use_ability_btn.offset_top = -70.0
	use_ability_btn.offset_bottom = -20.0
	use_ability_btn.remove_theme_font_size_override("font_size")
	skip_btn.offset_left = 20.0
	skip_btn.offset_right = 180.0
	skip_btn.offset_top = -70.0
	skip_btn.offset_bottom = -20.0
	skip_btn.remove_theme_font_size_override("font_size")

	# クリア画面ボタンを元の横並び配置に戻す
	share_btn.offset_left = -207.0
	share_btn.offset_right = -77.0
	share_btn.offset_top = 518.0
	share_btn.offset_bottom = 558.0
	share_btn.remove_theme_font_size_override("font_size")
	retry_btn.offset_left = -65.0
	retry_btn.offset_right = 65.0
	retry_btn.offset_top = 518.0
	retry_btn.offset_bottom = 558.0
	retry_btn.remove_theme_font_size_override("font_size")
	title_btn.offset_left = 77.0
	title_btn.offset_right = 207.0
	title_btn.offset_top = 518.0
	title_btn.offset_bottom = 558.0
	title_btn.remove_theme_font_size_override("font_size")

	# クリア画面リザルトボードを元の位置・サイズに戻す
	result_board.offset_left = -169.5
	result_board.offset_right = 169.5
	result_board.offset_top = 7.0
	result_board.offset_bottom = 513.0

	board_moves_label.offset_left = -7.0
	board_moves_label.offset_right = 48.0
	board_moves_label.offset_top = 29.0
	board_moves_label.offset_bottom = 65.0
	board_moves_label.remove_theme_font_size_override("font_size")

	clear_mode_label.offset_left = -123.0
	clear_mode_label.offset_right = 123.0
	clear_mode_label.offset_top = 111.0
	clear_mode_label.offset_bottom = 127.0
	clear_mode_label.remove_theme_font_size_override("font_size")

	clear_stats_container.offset_left = -123.0
	clear_stats_container.offset_right = 123.0
	clear_stats_container.offset_top = 130.5
	clear_stats_container.offset_bottom = 491.5


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
