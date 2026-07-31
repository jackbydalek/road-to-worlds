extends PanelContainer
class_name SketchPanelContainer

var fill_color := Color("#FFFAF0")
var outline_color := Color("#241B17")
var accent_color := Color.TRANSPARENT
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
	accent_color = accent
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
	draw_colored_polygon(_without_closing_point(outer), fill_color)
	draw_polyline(outer, outline_color, 3.0, true)
	var inner := _sketch_points(9.0, true)
	draw_polyline(inner, Color(outline_color.r, outline_color.g, outline_color.b, 0.66), 1.35, true)
	if accent_color.a > 0.0:
		var y := size.y - 9.0
		var wobble := 2.0 if sketch_variant % 2 == 0 else -2.0
		draw_polyline(
			PackedVector2Array([
				Vector2(18.0, y + wobble),
				Vector2(size.x * 0.34, y - 1.0),
				Vector2(size.x * 0.67, y + 1.5),
				Vector2(size.x - 17.0, y - wobble),
			]),
			accent_color,
			3.0,
			true
		)


func _sketch_points(inset: float, alternate: bool) -> PackedVector2Array:
	var flip := -1.0 if (sketch_variant + (1 if alternate else 0)) % 2 == 0 else 1.0
	var left := inset
	var top := inset
	var right := size.x - inset
	var bottom := size.y - inset
	return PackedVector2Array([
		Vector2(left + 3.0 * flip, top + 2.0),
		Vector2(size.x * 0.31, top - 1.5 * flip),
		Vector2(size.x * 0.69, top + 1.0 * flip),
		Vector2(right - 2.0 * flip, top + 3.0),
		Vector2(right + 1.0 * flip, size.y * 0.36),
		Vector2(right - 1.5 * flip, size.y * 0.72),
		Vector2(right - 3.0, bottom - 2.0 * flip),
		Vector2(size.x * 0.66, bottom + 1.0 * flip),
		Vector2(size.x * 0.29, bottom - 1.5 * flip),
		Vector2(left + 2.0 * flip, bottom - 3.0),
		Vector2(left - 1.0 * flip, size.y * 0.68),
		Vector2(left + 1.5 * flip, size.y * 0.32),
		Vector2(left + 3.0 * flip, top + 2.0),
	])


func _without_closing_point(points: PackedVector2Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for index in range(points.size() - 1):
		result.append(points[index])
	return result
