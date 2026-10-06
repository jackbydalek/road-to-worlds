extends Control
class_name BattleAngularSurface

const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const PAINT := preload("res://scripts/ui/PaintedUiShapes.gd")

var fill_color := PALETTE.PEACH_PAPER
var accent_color := PALETTE.PEACH_TEAL
var dark_surface := false
var show_inner_keyline := true
## Shared paper presentation. The flag remains for legacy explicit callers.
var peach_soda_style := true:
	set(value):
		peach_soda_style = value
		queue_redraw()


func configure(fill: Color, accent: Color, dark := false, inner_keyline := true) -> void:
	fill_color = fill
	accent_color = accent
	dark_surface = dark
	show_inner_keyline = inner_keyline
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	queue_redraw()


func _ready() -> void:
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	if size.x < 24.0 or size.y < 20.0:
		return
	# Keep the legacy configuration API, with one quiet native painted surface.
	# State borders belong to focused controls and real card silhouettes.
	PAINT.draw_surface(self, Rect2(Vector2(2, 2), size - Vector2(4, 4)), fill_color, 19, 10)
