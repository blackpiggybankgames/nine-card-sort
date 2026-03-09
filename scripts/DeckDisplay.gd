extends Node2D
class_name DeckDisplay

# 山札の表示を管理するクラス
# 9枚のカードを扇状に表示する

signal card_selected(card_number: int)
signal animation_completed  # アニメーション完了時

const CARD_SCENE_PATH = "res://scenes/Card.tscn"

# 表示設定
@export var fan_angle: float = 8.0      # 1枚あたりの角度
@export var card_spacing: float = 80.0  # カード間の水平距離
@export var vertical_offset: float = 5.0 # 1枚あたりの垂直オフセット

# アニメーション設定（後から調整しやすいように）
@export var animation_duration: float = 0.3  # アニメーション時間（秒）
@export var animation_enabled: bool = true   # アニメーション有効/無効

# 発動カード分離表示の設定
@export var active_card_offset_y: float = 120.0  # 発動カードを下にずらす距離

var card_nodes: Dictionary = {}  # card_number -> Card ノード
var deck_data: Array[int] = []
var is_animating: bool = false
var active_card_separated: bool = false  # 発動カードが分離表示中かどうか


func _ready() -> void:
	# 画面サイズに応じて位置を調整
	_update_position()
	get_viewport().size_changed.connect(_update_position)


func _update_position() -> void:
	# 画面中央に配置（やや上寄り）
	var viewport_size = get_viewport_rect().size
	position = Vector2(viewport_size.x / 2, viewport_size.y * 0.45)


# 山札をリセット（ゲーム再開時に呼び出す）
func reset() -> void:
	# 既存のカードを削除
	for card in card_nodes.values():
		if is_instance_valid(card):
			card.queue_free()
	card_nodes.clear()
	deck_data.clear()
	is_animating = false


# 山札を更新して表示（アニメーション付き）
func update_display(deck: Array[int]) -> void:
	var old_deck = deck_data.duplicate()
	deck_data = deck

	# 初回表示（カードがまだない場合）
	if card_nodes.is_empty():
		_create_all_cards(deck)
		return

	# アニメーションが有効な場合
	if animation_enabled and not old_deck.is_empty():
		_animate_cards_to_positions(deck)
	else:
		_update_card_positions_immediately(deck)


# 全カードを生成（初回のみ）
func _create_all_cards(deck: Array[int]) -> void:
	for i in range(deck.size()):
		var card_number = deck[i]
		var card = _create_card(card_number, i)
		add_child(card)
		card_nodes[card_number] = card


# カードを生成
func _create_card(card_number: int, index: int) -> Card:
	var card = Card.new()
	card.set_card_number(card_number)

	# コリジョン形状を追加
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(Card.CARD_WIDTH, Card.CARD_HEIGHT)
	collision.shape = shape
	card.add_child(collision)

	# ラベルを追加（カード番号表示）
	var label = Label.new()
	label.text = str(card_number)
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = Vector2(Card.CARD_WIDTH, Card.CARD_HEIGHT)
	label.position = Vector2(-Card.CARD_WIDTH/2, -Card.CARD_HEIGHT/2)
	card.add_child(label)

	# 位置と角度を設定（扇状配置）
	_set_card_position(card, index)

	# シグナル接続
	card.card_clicked.connect(_on_card_clicked)

	return card


# カードの位置・角度・z_indexを設定
func _set_card_position(card: Card, index: int) -> void:
	var center_index = 4  # 9枚の中心
	var offset_from_center = index - center_index

	# 位置と角度を反転して、一番上が右側に来るようにする
	card.position.x = -offset_from_center * card_spacing
	card.position.y = abs(offset_from_center) * vertical_offset
	card.rotation_degrees = -offset_from_center * fan_angle

	# Zインデックス（一番上のカード = index 0 を一番手前に表示）
	card.z_index = deck_data.size() - 1 - index


# インデックスから目標位置を計算
func _get_target_position(index: int) -> Vector2:
	var center_index = 4
	var offset_from_center = index - center_index
	return Vector2(
		-offset_from_center * card_spacing,
		abs(offset_from_center) * vertical_offset
	)


# インデックスから目標角度を計算
func _get_target_rotation(index: int) -> float:
	var center_index = 4
	var offset_from_center = index - center_index
	return -offset_from_center * fan_angle


# カードをアニメーションで移動
func _animate_cards_to_positions(deck: Array[int]) -> void:
	is_animating = true

	var tween = create_tween()
	tween.set_parallel(true)

	for i in range(deck.size()):
		var card_number = deck[i]
		var card = card_nodes.get(card_number)
		if card and is_instance_valid(card):
			var target_pos = _get_target_position(i)
			var target_rot = _get_target_rotation(i)
			var target_z = deck.size() - 1 - i

			# 位置と角度をアニメーション
			tween.tween_property(card, "position", target_pos, animation_duration)
			tween.tween_property(card, "rotation_degrees", target_rot, animation_duration)

			# z_indexは即座に更新（アニメーション中の表示順序）
			card.z_index = target_z

	# アニメーション完了時のコールバック
	tween.chain().tween_callback(_on_animation_finished)


# アニメーションなしで即座に位置を更新
func _update_card_positions_immediately(deck: Array[int]) -> void:
	for i in range(deck.size()):
		var card_number = deck[i]
		var card = card_nodes.get(card_number)
		if card and is_instance_valid(card):
			_set_card_position(card, i)


# アニメーション完了時
func _on_animation_finished() -> void:
	is_animating = false
	animation_completed.emit()


# カードがクリックされた時
func _on_card_clicked(card_number: int) -> void:
	# アニメーション中はクリックを無視
	if is_animating:
		return
	card_selected.emit(card_number)


# 全カードの選択可能状態を設定
func set_all_selectable(selectable: bool) -> void:
	for card in card_nodes.values():
		if is_instance_valid(card):
			card.set_selectable(selectable)


# 特定のカードを選択可能に設定
func set_card_selectable(card_number: int, selectable: bool) -> void:
	var card = card_nodes.get(card_number)
	if card and is_instance_valid(card):
		card.set_selectable(selectable)


# 一番上のカードをハイライト
func highlight_top_card() -> void:
	if deck_data.is_empty():
		return

	var top_card_number = deck_data[0]
	for card_number in card_nodes:
		var card = card_nodes[card_number]
		if is_instance_valid(card):
			card.set_highlighted(card_number == top_card_number)


# 全カードのハイライトを解除
func clear_highlights() -> void:
	for card in card_nodes.values():
		if is_instance_valid(card):
			card.set_highlighted(false)


# 特定のカードのハイライト状態を設定
func set_card_highlighted(card_number: int, highlighted: bool) -> void:
	var card = card_nodes.get(card_number)
	if card and is_instance_valid(card):
		card.set_highlighted(highlighted)


# 足して9になる組み合わせのカードを選択可能に
func set_sum9_selectable() -> void:
	for card_number in card_nodes:
		var card = card_nodes[card_number]
		if is_instance_valid(card):
			# 足して9になる相手がいるかチェック
			var partner = 9 - card_number
			if partner >= 1 and partner <= 9 and partner != card_number:
				if partner in deck_data:
					card.set_selectable(true)
				else:
					card.set_selectable(false)
			else:
				card.set_selectable(false)


# 指定したカードの隣接カードのみ選択可能に（能力4用）
func set_adjacent_selectable(first_card: int) -> void:
	var first_index = deck_data.find(first_card)
	if first_index == -1:
		return

	for card_number in card_nodes:
		var card = card_nodes[card_number]
		if is_instance_valid(card):
			var card_index = deck_data.find(card_number)
			# 隣接（差が1）かどうかチェック
			if abs(card_index - first_index) == 1:
				card.set_selectable(true)
				card.set_highlighted(true)  # 隣接カードもハイライト
			else:
				card.set_selectable(false)


# === 発動カード分離表示機能 ===

# 発動カード（一番上）を山札から分離して表示
# 手番開始時に呼び出す
func separate_active_card() -> void:
	if deck_data.is_empty():
		return

	var active_card_number = deck_data[0]
	var card = card_nodes.get(active_card_number)
	if not card or not is_instance_valid(card):
		return

	active_card_separated = true
	is_animating = true

	# 発動カードの目標位置（山札の下、中央寄り）
	var target_pos = Vector2(
		_get_target_position(0).x,  # X座標は一番右のまま
		active_card_offset_y  # Y座標は下にオフセット
	)
	var target_rot = 0.0  # 角度は水平に

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(card, "position", target_pos, animation_duration)
	tween.tween_property(card, "rotation_degrees", target_rot, animation_duration)

	# z_indexを最前面に
	card.z_index = 100

	tween.chain().tween_callback(_on_animation_finished)


# 発動カードを元の位置（山札の一番上）に戻す
# 能力キャンセル時などに呼び出す
func return_active_card_to_deck() -> void:
	if deck_data.is_empty() or not active_card_separated:
		return

	var active_card_number = deck_data[0]
	var card = card_nodes.get(active_card_number)
	if not card or not is_instance_valid(card):
		return

	active_card_separated = false
	is_animating = true

	# 元の位置に戻す
	var target_pos = _get_target_position(0)
	var target_rot = _get_target_rotation(0)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(card, "position", target_pos, animation_duration)
	tween.tween_property(card, "rotation_degrees", target_rot, animation_duration)

	# z_indexを戻す
	card.z_index = deck_data.size() - 1

	tween.chain().tween_callback(_on_animation_finished)


# 発動カードが分離表示中かどうか
func is_active_card_separated() -> bool:
	return active_card_separated


# 分離状態をリセット（山札更新時などに呼び出す）
func reset_separation() -> void:
	active_card_separated = false
