extends Button
class_name SketchButton

const PALETTE := preload("res://scripts/ui/GamePalette.gd")

var primary := false
var alternate := false
var ink := PALETTE.INK
var paper := PALETTE.GHOST
var action := PALETTE.TEAL


func configure(is_primary: bool, alternate_outline: bool) -> void:
	primary = is_primary
	alternate = alternate_outline
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	add_theme_color_override("font_color", PALETTE.GHOST if primary else ink)
	add_theme_color_override("font_hover_color", PALETTE.GHOST if primary else ink)
	add_theme_color_override("font_pressed_color", PALETTE.GHOST if primary else ink)
	add_theme_color_override("font_disabled_color", PALETTE.DISABLED_INK)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	if size.x < 8.0 or size.y < 8.0:
		return
	var pressed_offset := Vector2(0, 2) if button_pressed else Vector2.ZERO
	var points := _outline_points(pressed_offset)
	var fill := action if primary else paper
	if alternate and not primary:
		fill = PALETTE.APRICOT
	if disabled:
		fill = PALETTE.DISABLED
	elif is_hovered():
		fill = fill.lightened(0.08)

	var shadow := PackedVector2Array()
	for point in points:
		shadow.append(point + Vector2(3, 4))
	draw_colored_polygon(_without_closing_point(shadow), Color(0.08, 0.07, 0.05, 0.17))
	draw_colored_polygon(_without_closing_point(points), fill)
	_draw_rough_stroke(points, ink, 3.15, 7 if primary else 17, 0.42)
	_draw_rough_stroke(_offset_points(points, Vector2(-0.6, 0.65)), Color(ink, 0.34), 0.85, 29, 0.3)

	var inner := PackedVector2Array()
	for point in points:
		inner.append((point - size * 0.5) * Vector2(0.975, 0.82) + size * 0.5)
	_draw_rough_stroke(inner, Color(ink, 0.54), 1.0, 41, 0.24)

	# Button's built-in text is part of its normal drawing pass. Because this
	# control supplies the whole hand-drawn face, draw the label explicitly too.
	var font := get_theme_font("font")
	var font_size := get_theme_font_size("font_size")
	var label_color := PALETTE.GHOST if primary else ink
	if disabled:
		label_color = PALETTE.DISABLED_INK
	var label_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var label_position := Vector2(
		(size.x - label_size.x) * 0.5,
		(size.y + label_size.y) * 0.5 - 3.0
	) + pressed_offset
	draw_string(font, label_position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, label_color)


func _outline_points(offset: Vector2) -> PackedVector2Array:
	var left := 5.0
	var top := 5.0
	var right := size.x - 6.0
	var bottom := size.y - 6.0
	return PackedVector2Array([
		Vector2(left + 2, top + 1) + offset,
		Vector2(size.x * 0.18, top - 0.6) + offset,
		Vector2(size.x * 0.39, top + 1.0) + offset,
		Vector2(size.x * 0.62, top - 0.8) + offset,
		Vector2(size.x * 0.83, top + 0.7) + offset,
		Vector2(right - 1, top + 2) + offset,
		Vector2(right + 0.8, size.y * 0.28) + offset,
		Vector2(right - 0.7, size.y * 0.55) + offset,
		Vector2(right + 0.6, size.y * 0.78) + offset,
		Vector2(right - 2, bottom - 1) + offset,
		Vector2(size.x * 0.82, bottom + 0.5) + offset,
		Vector2(size.x * 0.61, bottom - 0.8) + offset,
		Vector2(size.x * 0.38, bottom + 0.7) + offset,
		Vector2(size.x * 0.17, bottom - 0.5) + offset,
		Vector2(left + 1, bottom - 2) + offset,
		Vector2(left - 0.7, size.y * 0.73) + offset,
		Vector2(left + 0.8, size.y * 0.47) + offset,
		Vector2(left - 0.6, size.y * 0.24) + offset,
		Vector2(left + 2, top + 1) + offset,
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
		var has_break := length > 40.0 and posmod(seed + segment_index * 3, 11) == 0
		if has_break:
			var center := 0.42 + 0.14 * (sin(float(seed + segment_index * 5)) * 0.5 + 0.5)
			var half_gap := minf(0.016, 0.75 / length)
			draw_line(start, start.lerp(finish, center - half_gap), color, width, true)
			draw_line(start.lerp(finish, center + half_gap), finish, color, width, true)
		else:
			draw_line(start, finish, color, width, true)


func _without_closing_point(points: PackedVector2Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for index in range(points.size() - 1):
		result.append(points[index])
	return result
