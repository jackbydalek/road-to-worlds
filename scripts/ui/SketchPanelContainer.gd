extends PanelContainer
class_name SketchPanelContainer

const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const SHAPES := preload("res://scripts/ui/PaintedUiShapes.gd")

var fill_color := PALETTE.PEACH_PAPER
var outline_color := PALETTE.PEACH_INK
var sketch_variant := 0


func configure(
	fill: Color,
	outline: Color,
	accent: Color,
	content_margins: Vector4,
	variant: int = 0
) -> void:
	set_meta("painted_shapes", true)
	fill_color = fill
	outline_color = outline
	# Accent is retained in the API so existing callers do not need to know how
	# the panel is drawn, but frames are deliberately monochrome.
	var _unused_accent := accent
	sketch_variant = variant
	var spacing := StyleBoxEmpty.new()
	spacing.content_margin_left = content_margins.x
	spacing.content_margin_top = content_margins.y
	spacing.content_margin_right = content_margins.z
	spacing.content_margin_bottom = content_margins.w
	add_theme_stylebox_override("panel", spacing)
	queue_redraw()


func _ready() -> void:
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	if size.x < 10.0 or size.y < 10.0:
		return
	# Layout margins and input remain native; only the matte face is painted.
	SHAPES.draw_surface(self, Rect2(Vector2(3, 3), size - Vector2(6, 6)), fill_color, sketch_variant)
