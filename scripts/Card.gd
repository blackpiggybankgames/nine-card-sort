extends Area2D
class_name Card

# カード1枚を表すクラス

signal card_clicked(card_number: int)

@export var card_number: int = 1

# カードのサイズ
const CARD_WIDTH: float = 100.0
const CARD_HEIGHT: float = 150.0

# カードの色（アンティーク・カジノスタイルのアースカラー）
var card_colors: Dictionary = {
	1: Color(0.55, 0.12, 0.12),  # バーガンディ
	2: Color(0.62, 0.38, 0.08),  # アンバー
	3: Color(0.50, 0.45, 0.08),  # マスタード
	4: Color(0.15, 0.35, 0.18),  # ハンターグリーン
	5: Color(0.15, 0.35, 0.38),  # ティール
	6: Color(0.16, 0.20, 0.45),  # ネイビー
	7: Color(0.35, 0.15, 0.42),  # プラム
	8: Color(0.48, 0.22, 0.30),  # モーブ
	9: Color(0.32, 0.28, 0.24),  # ピューター
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

	# アースカラーを薄く重ねて羊皮紙ベースを活かす
	var overlay = card_colors.get(card_number, Color.WHITE)
	overlay.a = 0.25
	draw_rect(card_rect, overlay)

	# 枠線（選択可能: ホワイトゴールドグロー3層、通常: ダークブラウン）
	if is_selectable:
		var g := Color(1.0, 0.96, 0.70)
		draw_rect(card_rect.grow(6), Color(g.r, g.g, g.b, 0.10), false, 6.0)
		draw_rect(card_rect.grow(3), Color(g.r, g.g, g.b, 0.28), false, 3.5)
		draw_rect(card_rect.grow(1), Color(g.r, g.g, g.b, 0.88), false, 2.5)
	else:
		draw_rect(card_rect, Color(0.29, 0.24, 0.16), false, 2.0)


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
	# 選択可能時に1.05倍へ拡大して浮き上がりを演出
	var tween := create_tween()
	if selectable:
		tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.15)
	else:
		tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.12)


# ハイライト状態を設定
func set_highlighted(highlighted: bool) -> void:
	is_highlighted = highlighted
	queue_redraw()
