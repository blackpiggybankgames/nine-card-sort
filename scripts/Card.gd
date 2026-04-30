extends Area2D
class_name Card

# カード1枚を表すクラス

signal card_clicked(card_number: int)

@export var card_number: int = 1

# カードのサイズ
const CARD_WIDTH: float = 100.0
const CARD_HEIGHT: float = 150.0

# カードの色（数字ごとに異なる色）
var card_colors: Dictionary = {
	1: Color(0.9, 0.3, 0.3),   # 赤
	2: Color(0.9, 0.6, 0.2),   # オレンジ
	3: Color(0.9, 0.9, 0.2),   # 黄色
	4: Color(0.4, 0.8, 0.3),   # 緑
	5: Color(0.3, 0.7, 0.9),   # 水色
	6: Color(0.3, 0.4, 0.9),   # 青
	7: Color(0.6, 0.3, 0.9),   # 紫
	8: Color(0.9, 0.4, 0.7),   # ピンク
	9: Color(0.5, 0.5, 0.5),   # グレー
}

var is_selectable: bool = false  # 選択可能かどうか
var is_highlighted: bool = false  # ハイライト表示中かどうか

var _card_texture: Texture2D = preload("res://assets/images/cards/card_paper_texture.png")


func _ready() -> void:
	# 入力イベントを有効化
	input_pickable = true


func _draw() -> void:
	var card_rect = Rect2(-CARD_WIDTH/2, -CARD_HEIGHT/2, CARD_WIDTH, CARD_HEIGHT)

	# 羊皮紙テクスチャを背景として描画
	draw_texture_rect(_card_texture, card_rect, false)

	# 数字ごとの識別色を半透明オーバーレイで重ねる
	var overlay = card_colors.get(card_number, Color.WHITE)
	overlay.a = 0.35
	draw_rect(card_rect, overlay)

	# 枠線（選択可能時は黄色く太く）
	var border_color = Color.BLACK if not is_selectable else Color.YELLOW
	var border_width = 2.0 if not is_selectable else 4.0
	draw_rect(card_rect, border_color, false, border_width)


# グローバル入力イベントでクリック検出
func _input(event: InputEvent) -> void:
	# 非表示または選択不可の場合はイベントを無視
	if not is_visible_in_tree():
		return

	# 選択不可の場合はイベントを処理しない（他のUI要素へ伝播させる）
	if not is_selectable:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# マウス位置がこのカードの範囲内かチェック
			var mouse_pos = get_global_mouse_position()
			if _is_point_inside(mouse_pos):
				card_clicked.emit(card_number)
				# このイベントを処理済みにする
				get_viewport().set_input_as_handled()


# 指定した点がカードの範囲内かチェック
func _is_point_inside(point: Vector2) -> bool:
	# グローバル座標をローカル座標に変換
	var local_point = to_local(point)
	# カードの矩形範囲内かチェック
	var rect = Rect2(-CARD_WIDTH/2, -CARD_HEIGHT/2, CARD_WIDTH, CARD_HEIGHT)
	return rect.has_point(local_point)


# カード番号を設定
func set_card_number(number: int) -> void:
	card_number = number
	queue_redraw()


# 選択可能状態を設定
func set_selectable(selectable: bool) -> void:
	is_selectable = selectable
	queue_redraw()


# ハイライト状態を設定
func set_highlighted(highlighted: bool) -> void:
	is_highlighted = highlighted
	queue_redraw()
