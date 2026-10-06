extends Control
class_name TurnChangeGraphic

const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const SKETCH := preload("res://scripts/ui/WarmSketch.gd")

var accent_color := PALETTE.PEACH_TEAL


func configure(accent: Color) -> void:
	accent_color = accent
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	queue_redraw()


func _ready() -> void:
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	if size.x < 80.0 or size.y < 50.0:
		return
	# A small tournament slip carries the turn announcement over the table.
	var sheet := StyleBoxFlat.new()
	sheet.bg_color = PALETTE.PEACH_PAPER
	sheet.border_color = PALETTE.PEACH_EDGE
	sheet.set_border_width_all(1)
	sheet.set_corner_radius_all(6)
	sheet.shadow_color = Color(PALETTE.PEACH_INK, 0.24)
	sheet.shadow_size = 2
	sheet.shadow_offset = Vector2(0, 3)
	SKETCH.paper(self, Rect2(Vector2(2, 2), size - Vector2(7, 8)), PALETTE.PEACH_PAPER)
	var divider_y := size.y * 0.64
	draw_line(Vector2(18, divider_y), Vector2(size.x - 24, divider_y), Color(PALETTE.PEACH_EDGE, 0.4), 1.0, true)
	draw_line(Vector2(18, 8), Vector2(112, 8), accent_color, 3.0, true)
