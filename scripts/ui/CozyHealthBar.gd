extends ProgressBar
class_name CozyHealthBar

## Native matte paint track and proportional fill. The historical class name
## remains compatible with live health, damage trails and saved UI callers.
const PAINT := preload("res://scripts/ui/PaintedUiShapes.gd")
const PALETTE := preload("res://scripts/ui/GamePalette.gd")

var draw_track := false
var fill_color := PALETTE.PEACH_HEALTH


func _init() -> void:
	show_percentage = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Geometry stays local and retained; health never rebuilds a bitmap skin.
	add_theme_stylebox_override("background", StyleBoxEmpty.new())
	add_theme_stylebox_override("fill", StyleBoxEmpty.new())
	value_changed.connect(func(_value: float) -> void: queue_redraw())
	changed.connect(queue_redraw)
	resized.connect(queue_redraw)


func fill_rect() -> Rect2:
	var inset := Vector2(2, 4)
	var interior := Rect2(inset, (size - inset * 2.0).max(Vector2.ZERO))
	var fraction := clampf(ratio, 0.0, 1.0)
	var width := interior.size.x * fraction
	if fill_mode == ProgressBar.FILL_END_TO_BEGIN:
		interior.position.x += interior.size.x - width
	interior.size.x = width
	return interior


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	if draw_track:
		PAINT.draw_surface(self, Rect2(Vector2(2, 4), (size - Vector2(4, 8)).max(Vector2.ZERO)), PALETTE.PEACH_MINT, 71, 7)
	var filled := fill_rect()
	if filled.size.x > 0.0 and filled.size.y > 0.0:
		PAINT.draw_surface(self, filled, fill_color, 71, minf(7, filled.size.x * 0.5))
