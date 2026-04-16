extends Node2D
class_name InsertionArrow

# 挿入位置選択時に表示する下向き三角矢印ノード
# クリックされると insertion_clicked シグナルを送出する

signal insertion_clicked(deck9_idx: int)

const HALF: float = 18.0  # クリック判定の半幅

var deck9_idx: int = -1  # この矢印が示す 9-deck インデックス


func _init(idx: int = -1) -> void:
	deck9_idx = idx


func _draw() -> void:
	# 下向き三角形（▼）
	var points = PackedVector2Array([
		Vector2(-HALF,      -HALF * 0.5),
		Vector2( HALF,      -HALF * 0.5),
		Vector2( 0.0,        HALF)
	])
	draw_colored_polygon(points, Color.YELLOW)
	# 黒枠線
	var outline = PackedVector2Array([points[0], points[1], points[2], points[0]])
	draw_polyline(outline, Color.BLACK, 2.0)


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if _is_hit(get_global_mouse_position()):
			insertion_clicked.emit(deck9_idx)
			get_viewport().set_input_as_handled()


func _is_hit(global_pos: Vector2) -> bool:
	var local_pos = to_local(global_pos)
	return Rect2(-HALF, -HALF, HALF * 2.0, HALF * 2.0).has_point(local_pos)
