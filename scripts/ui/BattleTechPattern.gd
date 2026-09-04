extends Control
class_name BattleTechPattern

const PALETTE := preload("res://scripts/ui/GamePalette.gd")

var accent := PALETTE.SKY
var dense := false


func configure(accent_color: Color, dense_pattern := false) -> void:
	accent = accent_color
	dense = dense_pattern
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	queue_redraw()


func _ready() -> void:
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	if size.x < 20.0 or size.y < 16.0:
		return
	var cell := 10.0 if dense else 14.0
	var line_color := Color(accent, 0.075 if dense else 0.055)
	var column_count := ceili(size.x / cell)
	var row_count := ceili(size.y / cell)
	for column_index in range(column_count + 1):
		var x := float(column_index) * cell
		draw_line(Vector2(x, 0), Vector2(x, size.y), line_color, 1.0, true)
	for row_index in range(row_count + 1):
		var y := float(row_index) * cell
		draw_line(Vector2(0, y), Vector2(size.x, y), line_color, 1.0, true)
	var diagonal_color := Color(accent, 0.045 if dense else 0.03)
	draw_colored_polygon(PackedVector2Array([
		Vector2(size.x * 0.56, 0),
		Vector2(size.x, 0),
		Vector2(size.x, size.y),
		Vector2(size.x * 0.74, size.y),
	]), diagonal_color)
