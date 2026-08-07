extends PanelContainer
class_name SketchPanelContainer

const PALETTE := preload("res://scripts/ui/GamePalette.gd")

var fill_color := PALETTE.GHOST
var outline_color := PALETTE.INK
var sketch_variant := 0


func configure(
	fill: Color,
	outline: Color,
	accent: Color,
	content_margins: Vector4,
	variant: int = 0
) -> void:
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
	var outer := _sketch_points(5.0, false)
	var fill_shape := _fill_points(5.0)
	var display_fill := PALETTE.GHOST_PRESSED if fill_color.is_equal_approx(PALETTE.GHOST) else fill_color
	var shadow := _offset_points(fill_shape, Vector2(3.0, 5.0))
	draw_colored_polygon(shadow, Color(0.08, 0.05, 0.16, 0.24))
	draw_colored_polygon(fill_shape, display_fill)
	# Vary both the path and pen pressure along each edge. A faint second pass is
	# slightly off-register, like the artist retraced part of the frame.
	_draw_rough_stroke(outer, outline_color, 3.35, sketch_variant * 13 + 5, 0.48)
	_draw_rough_stroke(_offset_points(outer, Vector2(-0.7, 0.65)), Color(outline_color, 0.34), 0.9, sketch_variant * 19 + 2, 0.34)
	var inner := _sketch_points(9.0, true)
	_draw_rough_stroke(inner, Color(outline_color, 0.55), 1.05, sketch_variant * 23 + 9, 0.28)


func _sketch_points(inset: float, alternate: bool) -> PackedVector2Array:
	var flip := -1.0 if (sketch_variant + (1 if alternate else 0)) % 2 == 0 else 1.0
	var left := inset
	var top := inset
	var right := size.x - inset
	var bottom := size.y - inset
	return PackedVector2Array([
		Vector2(left + 3.0 * flip, top + 2.0),
		Vector2(size.x * 0.17, top - 0.8 * flip),
		Vector2(size.x * 0.38, top + 1.4 * flip),
		Vector2(size.x * 0.61, top - 1.1 * flip),
		Vector2(size.x * 0.84, top + 0.7 * flip),
		Vector2(right - 2.0 * flip, top + 3.0),
		Vector2(right + 0.8 * flip, size.y * 0.22),
		Vector2(right - 1.2 * flip, size.y * 0.47),
		Vector2(right + 1.1 * flip, size.y * 0.73),
		Vector2(right - 3.0, bottom - 2.0 * flip),
		Vector2(size.x * 0.82, bottom + 0.6 * flip),
		Vector2(size.x * 0.62, bottom - 1.2 * flip),
		Vector2(size.x * 0.39, bottom + 1.0 * flip),
		Vector2(size.x * 0.18, bottom - 0.7 * flip),
		Vector2(left + 2.0 * flip, bottom - 3.0),
		Vector2(left - 0.7 * flip, size.y * 0.78),
		Vector2(left + 1.2 * flip, size.y * 0.53),
		Vector2(left - 0.8 * flip, size.y * 0.27),
		Vector2(left + 3.0 * flip, top + 2.0),
	])


func _fill_points(inset: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(inset + 1.0, inset + 1.0),
		Vector2(size.x - inset - 1.0, inset + 1.5),
		Vector2(size.x - inset - 1.5, size.y - inset - 1.0),
		Vector2(inset + 1.5, size.y - inset - 1.5),
	])


func _offset_points(points: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points:
		result.append(point + offset)
	return result


func _draw_rough_stroke(
	points: PackedVector2Array,
	color: Color,
	base_width: float,
	seed: int,
	_break_scale: float
) -> void:
	for segment_index in range(points.size() - 1):
		var start := points[segment_index]
		var finish := points[segment_index + 1]
		var length := start.distance_to(finish)
		var pressure := 0.88 + 0.18 * (sin(float(seed + segment_index * 7) * 1.17) * 0.5 + 0.5)
		var width := maxf(0.6, base_width * pressure)
		# Only some sufficiently long strokes have a tiny dry-brush break.
		var has_break := length > 48.0 and posmod(seed + segment_index * 3, 11) == 0
		if has_break:
			var center := 0.42 + 0.14 * (sin(float(seed + segment_index * 5)) * 0.5 + 0.5)
			var half_gap := minf(0.014, 0.85 / length)
			draw_line(start, start.lerp(finish, center - half_gap), color, width, true)
			draw_line(start.lerp(finish, center + half_gap), finish, color, width, true)
		else:
			draw_line(start, finish, color, width, true)


func _without_closing_point(points: PackedVector2Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for index in range(points.size() - 1):
		result.append(points[index])
	return result
