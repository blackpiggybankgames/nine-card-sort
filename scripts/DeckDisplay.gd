extends Node2D
class_name DeckDisplay

# 山札の表示を管理するクラス
# 9枚のカードを扇状に表示する

signal card_selected(card_number: int)
signal animation_completed  # アニメーション完了時
signal insertion_point_selected(deck9_idx: int)  # 挿入位置矢印クリック時

const CARD_SCENE_PATH = "res://scenes/Card.tscn"

# 表示設定
@export var fan_angle: float = 8.0      # 1枚あたりの角度
@export var card_spacing: float = 40.0  # カード間の水平距離（390px 幅基準）
@export var vertical_offset: float = 5.0 # 1枚あたりの垂直オフセット

# アニメーション設定（後から調整しやすいように）
@export var animation_duration: float = 0.3  # 通常アニメーション時間（秒）
@export var animation_enabled: bool = true   # アニメーション有効/無効

# コの字アニメーション設定
@export var fly_height: float = -120.0          # 飛び出し高さ（DeckDisplay中心からの相対Y）
@export var fly_depth: float = 150.0            # 底面パス時の最下点Y（発動カードが下側にある場合）
@export var fly_up_duration: float = 0.15       # 上昇フェーズの時間（秒）
@export var fly_horizontal_duration: float = 0.2 # 水平移動フェーズの時間（秒）
@export var fly_down_duration: float = 0.15     # 降下フェーズの時間（秒）

# 発動カード分離表示の設定
@export var active_card_offset_y: float = 90.0   # 発動カードを下にずらす距離

var card_nodes: Dictionary = {}  # card_number -> Card ノード
var deck_data: Array[int] = []
var is_animating: bool = false
var active_card_separated: bool = false  # 発動カードが分離表示中かどうか
var _insertion_arrows: Array = []  # 挿入位置矢印ノードの配列


func _ready() -> void:
	# 画面サイズに応じて位置を調整
	_update_position()
	get_viewport().size_changed.connect(_update_position)


func _update_position() -> void:
	var viewport_size = get_viewport_rect().size
	position = Vector2(viewport_size.x / 2, viewport_size.y * 0.45)

	if not deck_data.is_empty():
		_update_card_positions_immediately(deck_data)


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
		_animate_cards_to_positions(deck, old_deck)
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
	# 文字色にカードのアースカラーを使用して識別性を高める
	var label = Label.new()
	label.text = str(card_number)
	label.add_theme_font_size_override("font_size", 28)
	# アースカラーをウォームブラウンへ40%ブレンドして彩度を落とし羊皮紙に馴染む色調に
	var raw_color = card.card_colors.get(card_number, Color(0.29, 0.24, 0.16))
	var text_color = raw_color.lerp(Color(0.38, 0.30, 0.22), 0.40)
	label.add_theme_color_override("font_color", text_color)
	label.add_theme_color_override("font_outline_color", Color(0.96, 0.90, 0.78, 0.85))
	label.add_theme_constant_override("outline_size", 3)
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
# コの字（U字）アニメーションを適用するか判定してから実行
func _animate_cards_to_positions(deck: Array[int], old_deck: Array[int]) -> void:
	is_animating = true

	# 大きく移動するカード（位置変化 > 1）を特定
	# 旧デッキに存在しないカード（発動カードが戻ってくる場合）は最大移動扱い
	const BIG_MOVE_THRESHOLD: int = 1
	var main_mover: int = -1
	var big_movers_count: int = 0

	for card_num in deck:
		var old_idx: int = old_deck.find(card_num)
		var new_idx: int = deck.find(card_num)
		var displacement: int
		if old_idx == -1:
			displacement = 999  # 旧デッキに存在しない = 大移動とみなす
		else:
			displacement = abs(new_idx - old_idx)
		if displacement > BIG_MOVE_THRESHOLD:
			big_movers_count += 1
			if big_movers_count == 1:
				main_mover = card_num

	# 大きく移動するカードが1枚だけならコの字アニメーション
	if big_movers_count == 1 and main_mover != -1:
		_animate_u_shape(deck, main_mover)
	else:
		_animate_cards_simple(deck)


# コの字（U字）アニメーション
# 通常: 対象カードを上に飛ばし → 横移動 → 降下
# 発動カードが下側にある場合（分離表示中）: 下に潜る → 横移動 → 目標位置へ上昇
func _animate_u_shape(deck: Array[int], main_mover: int) -> void:
	var mover_card = card_nodes.get(main_mover)
	if not mover_card or not is_instance_valid(mover_card):
		# フォールバック: 通常アニメーション
		_animate_cards_simple(deck)
		return

	var new_idx: int = deck.find(main_mover)
	var target_pos: Vector2 = _get_target_position(new_idx)
	var target_rot: float = _get_target_rotation(new_idx)

	# メインムーバーを最前面に表示
	mover_card.z_index = 200

	# 発動カードが下側（分離表示中）にある場合は底面パスを使用
	var use_bottom_path: bool = mover_card.position.y > active_card_offset_y * 0.5

	if use_bottom_path:
		# 底面パス: 下に潜る（Y増加・回転を水平に）→ 水平移動 → 目標位置へ上昇
		var tween1 = create_tween()
		tween1.set_parallel(true)
		tween1.tween_property(mover_card, "position:y", fly_depth, fly_up_duration)
		tween1.tween_property(mover_card, "rotation_degrees", 0.0, fly_up_duration)
		await tween1.finished

		var tween2 = create_tween()
		tween2.tween_property(mover_card, "position:x", target_pos.x, fly_horizontal_duration)
		await tween2.finished
	else:
		# 上部パス: 上に飛び出す（Y減少・回転を水平に）→ 水平移動
		var tween1 = create_tween()
		tween1.set_parallel(true)
		tween1.tween_property(mover_card, "position:y", fly_height, fly_up_duration)
		tween1.tween_property(mover_card, "rotation_degrees", 0.0, fly_up_duration)
		await tween1.finished

		var tween2 = create_tween()
		tween2.tween_property(mover_card, "position:x", target_pos.x, fly_horizontal_duration)
		await tween2.finished

	# フェーズ3: 目標位置へ移動 + 他カードも同時に移動（隙間を詰める）
	var tween3 = create_tween()
	tween3.set_parallel(true)

	tween3.tween_property(mover_card, "position:y", target_pos.y, fly_down_duration)
	tween3.tween_property(mover_card, "rotation_degrees", target_rot, fly_down_duration)
	mover_card.z_index = deck.size() - 1 - new_idx

	for i in range(deck.size()):
		var card_num: int = deck[i]
		if card_num == main_mover:
			continue
		var card = card_nodes.get(card_num)
		if card and is_instance_valid(card):
			var tp: Vector2 = _get_target_position(i)
			var tr: float = _get_target_rotation(i)
			tween3.tween_property(card, "position", tp, fly_down_duration)
			tween3.tween_property(card, "rotation_degrees", tr, fly_down_duration)
			card.z_index = deck.size() - 1 - i

	tween3.chain().tween_callback(_on_animation_finished)


# 山札を更新して表示（コの字なし・一直線アニメーション固定）
# 発動カードを一番下へ移動する最終ステップ用
func update_display_simple(deck: Array[int]) -> void:
	deck_data = deck
	if animation_enabled:
		_animate_cards_simple(deck)
	else:
		_update_card_positions_immediately(deck)


# 通常アニメーション（全カードを同時に目標位置へ移動）
func _animate_cards_simple(deck: Array[int]) -> void:
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


# 端以外のカードを選択可能に（カード4「どかす」用）
# 発動カード除外後の8枚で、index 0 と index 7 は選択不可
# deck_dataには発動カード(index 0)を含む9枚が入っている
# 8枚の端 = 9枚のindex 1（左端）と index 8（右端）
func set_non_edge_selectable() -> void:
	for card_number in card_nodes:
		var card = card_nodes[card_number]
		if is_instance_valid(card):
			var card_index = deck_data.find(card_number)
			card.set_selectable(card_index > 1 and card_index < deck_data.size() - 1)


# 3枚グループの先頭カードを選択可能に（カード2「3枚順繰り」用）
# 有効な9-card index: 1〜(size-3)
# 8-card index 0〜5が有効（後ろに2枚必要）
func set_trio_top_selectable() -> void:
	for card_number in card_nodes:
		var card = card_nodes[card_number]
		if is_instance_valid(card):
			var idx = deck_data.find(card_number)
			card.set_selectable(idx >= 1 and idx <= deck_data.size() - 3)


# ペアトップカードを選択可能に（カード6「2セット下送り」ステップ1用）
# 有効な9-card index: 1〜(size-2)（最後のカードはペアにならない）
func set_pair_top_selectable() -> void:
	for card_number in card_nodes:
		var card = card_nodes[card_number]
		if is_instance_valid(card):
			var idx = deck_data.find(card_number)
			card.set_selectable(idx >= 1 and idx <= deck_data.size() - 2)


# 1組目を除いたペアトップカードを選択可能に（カード6ステップ2用）
# first_pair_top: ステップ1で選んだ1組目の上側カード
func set_pair_top_selectable_excluding(first_pair_top: int) -> void:
	var first_pair_idx = deck_data.find(first_pair_top)
	for card_number in card_nodes:
		var card = card_nodes[card_number]
		if is_instance_valid(card):
			var idx = deck_data.find(card_number)
			var is_valid_pair_top = idx >= 1 and idx <= deck_data.size() - 2
			# 1組目のペア（first_pair_idx, first_pair_idx+1）と重複する位置はNG
			# 重複条件: |idx - first_pair_idx| <= 1
			var overlaps_first = abs(idx - first_pair_idx) <= 1
			card.set_selectable(is_valid_pair_top and not overlaps_first)


# ギャップ右側カードを選択可能に（カード7「3枚ブロック差し込み」旧ステップ1用）
# 有効な9-card index: 2〜(size-1)（左隣のカードが必要なので先頭の次以降）
func set_gap_right_selectable() -> void:
	for card_number in card_nodes:
		var card = card_nodes[card_number]
		if is_instance_valid(card):
			var idx = deck_data.find(card_number)
			card.set_selectable(idx >= 2)


# ブロック中央カードを選択可能に（カード7「3枚ブロック差し込み」新ステップ1用）
# 前後1枚が必要なため両端不可: 8-card index 1〜6 = 9-card index 2〜7
func set_block_center_any_selectable() -> void:
	for card_number in card_nodes:
		var card = card_nodes[card_number]
		if is_instance_valid(card):
			var idx = deck_data.find(card_number)
			var j = idx - 1  # 8-card index（発動カードがindex 0にいるためオフセット）
			card.set_selectable(j >= 1 and j <= 6)


# ブロック中央カードを選択可能に（カード7ステップ2用）
# gap_right_card: ステップ1で選んだギャップ右側カード
# ブロック中央の条件: 8-card index 1〜6（両端不可）かつ差し込み先の隣ではない
func set_block_center_selectable(gap_right_card: int) -> void:
	var gap_9idx = deck_data.find(gap_right_card)
	# 8-card index = 9-card index - 1（発動カードがindex 0にいるため）
	var gap_i = gap_9idx - 1  # ギャップ右側の8-card index
	for card_number in card_nodes:
		var card = card_nodes[card_number]
		if is_instance_valid(card):
			var idx_9 = deck_data.find(card_number)
			var j = idx_9 - 1  # 8-card index
			# 両端を除く（前後1枚ずつ必要）
			var is_valid_center = j >= 1 and j <= 6
			# ブロック内にギャップ右側カードが含まれる場合は選択不可
			# ギャップ右 = gap_i として、j-1/j/j+1 のいずれかが gap_i になる場合を除外
			var adjacent_to_gap = (j == gap_i - 1 or j == gap_i or j == gap_i + 1)
			card.set_selectable(is_valid_center and not adjacent_to_gap)


# ペアトップカードを選択可能に（カード9「4枚逆順」用）
# 外側2枚が存在する条件: 8-card index 1〜5
# 9-card index: 2〜6
func set_four_reverse_pair_selectable() -> void:
	for card_number in card_nodes:
		var card = card_nodes[card_number]
		if is_instance_valid(card):
			var idx = deck_data.find(card_number)
			var j = idx - 1  # 8-card index
			card.set_selectable(j >= 1 and j <= 5)


# 挿入位置カードを選択可能に（カード8裏面ステップ2用）
# card_to_move: 移動するカード（これは選択不可）
func set_insertion_target_selectable(card_to_move: int) -> void:
	for card_number in card_nodes:
		var card = card_nodes[card_number]
		if is_instance_valid(card):
			card.set_selectable(card_number != card_to_move)


# カード1（±1入れ替え）ステップ2用: ±1の数値のカードを選択可能に
# source_card: ステップ1で選んだカード
func set_adjacent_value_selectable(source_card: int) -> void:
	for card_number in card_nodes:
		var card = card_nodes[card_number]
		if is_instance_valid(card):
			card.set_selectable(abs(card_number - source_card) == 1)


# カード2・9の多段選択用: 選択済みグループの両端に隣接するカードのみ選択可能に
# already_selected: 選択済みカード番号の配列（1枚以上）
func set_adjacent_extension_selectable(already_selected: Array[int]) -> void:
	var selected_8deck: Array[int] = []
	for cn in already_selected:
		selected_8deck.append(deck_data.find(cn) - 1)  # 8-card index

	var lo: int = selected_8deck[0]
	var hi: int = selected_8deck[0]
	for j in selected_8deck:
		if j < lo:
			lo = j
		if j > hi:
			hi = j

	for card_number in card_nodes:
		var card = card_nodes[card_number]
		if is_instance_valid(card):
			var k = deck_data.find(card_number) - 1
			card.set_selectable((k == lo - 1 and k >= 0) or (k == hi + 1 and k <= 7))


# カード6の2組目開始カードを選択可能に
# pair1_selected: 1組目として選んだカード番号の配列（2枚）
func set_card6_pair2_start_selectable(pair1_selected: Array[int]) -> void:
	var p1_idxs: Array[int] = []
	for cn in pair1_selected:
		p1_idxs.append(deck_data.find(cn) - 1)

	var lo: int = p1_idxs[0]
	for j in p1_idxs:
		if j < lo:
			lo = j

	for card_number in card_nodes:
		var card = card_nodes[card_number]
		if is_instance_valid(card):
			var k = deck_data.find(card_number) - 1
			if k in p1_idxs:
				card.set_selectable(false)
				continue
			# ペア (k, k+1): pair_top=k、|k - lo| >= 2 が必要
			var can_pair_right = (k + 1 <= 7) and ((k + 1) not in p1_idxs) and (abs(k - lo) >= 2)
			# ペア (k-1, k): pair_top=k-1、|k-1 - lo| >= 2 が必要
			var can_pair_left = (k - 1 >= 0) and ((k - 1) not in p1_idxs) and (abs(k - 1 - lo) >= 2)
			card.set_selectable(can_pair_right or can_pair_left)


# カード6の2組目の2枚目を選択可能に（2組目の1枚目に隣接するカード）
# all_selected: 選択済みカード番号 [pair1_a, pair1_b, pair2_start]
func set_card6_pair2_adjacent_selectable(all_selected: Array[int]) -> void:
	var pair1_idxs: Array[int] = []
	for i in range(2):
		pair1_idxs.append(deck_data.find(all_selected[i]) - 1)
	var pair2_start_idx = deck_data.find(all_selected[2]) - 1

	for card_number in card_nodes:
		var card = card_nodes[card_number]
		if is_instance_valid(card):
			var k = deck_data.find(card_number) - 1
			var is_adjacent = (k == pair2_start_idx - 1 or k == pair2_start_idx + 1)
			var not_already = (k not in pair1_idxs) and (k != pair2_start_idx)
			card.set_selectable(is_adjacent and not_already and k >= 0 and k <= 7)


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


# カードをカスタム速度でアニメーション（クリア後の山札ソート表示用）
func update_display_with_duration(deck: Array[int], duration: float) -> void:
	deck_data = deck
	if animation_enabled:
		_animate_cards_with_duration(deck, duration)
	else:
		_update_card_positions_immediately(deck)


# === 挿入位置矢印 ===

# 挿入位置矢印を表示する
# valid_deck9_indices: 矢印を表示する 9-deck インデックスのリスト
# インデックス k の矢印は「deck_data[k] の直前に挿入」を意味する
func show_insertion_arrows(valid_deck9_indices: Array) -> void:
	hide_insertion_arrows()
	for idx in valid_deck9_indices:
		# X座標: 9-deck[idx-1] と 9-deck[idx] の中間点
		var arrow_x: float
		if idx <= 0:
			arrow_x = _get_target_position(0).x + card_spacing * 0.5
		else:
			arrow_x = (_get_target_position(idx - 1).x + _get_target_position(idx).x) * 0.5
		# Y座標: カードファンの上方に固定
		var arrow = InsertionArrow.new(idx)
		arrow.position = Vector2(arrow_x, -60.0)
		arrow.insertion_clicked.connect(func(i): insertion_point_selected.emit(i))
		add_child(arrow)
		_insertion_arrows.append(arrow)


# 挿入位置矢印を非表示にして削除する
func hide_insertion_arrows() -> void:
	for arrow in _insertion_arrows:
		if is_instance_valid(arrow):
			arrow.queue_free()
	_insertion_arrows.clear()


func _animate_cards_with_duration(deck: Array[int], duration: float) -> void:
	var tween = create_tween()
	tween.set_parallel(true)

	for i in range(deck.size()):
		var card_number = deck[i]
		var card = card_nodes.get(card_number)
		if card and is_instance_valid(card):
			var target_pos = _get_target_position(i)
			var target_rot = _get_target_rotation(i)
			var target_z = deck.size() - 1 - i

			tween.tween_property(card, "position", target_pos, duration)
			tween.tween_property(card, "rotation_degrees", target_rot, duration)
			card.z_index = target_z

	tween.chain().tween_callback(_on_animation_finished)
