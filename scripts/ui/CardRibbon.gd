extends Control
class_name CardRibbon

const PALETTE := preload("res://scripts/ui/GamePalette.gd")
const LABEL_FONT := preload("res://assets/fonts/AtkinsonHyperlegibleNext.ttf")

var left_color: Color = PALETTE.PEACH_TABLE
var right_color: Color = PALETTE.PEACH_TABLE
var dual_affinity := false
var label_text := "INGREDIENT"
var detail_text := ""
var draw_copy := true


func configure(
	primary_color: Color,
	secondary_color: Color = Color.TRANSPARENT,
	title: String = "INGREDIENT",
	detail: String = ""
) -> void:
	left_color = primary_color
	right_color = secondary_color if secondary_color.a > 0.0 else primary_color
	dual_affinity = secondary_color.a > 0.0
	label_text = title
	detail_text = detail
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	if size.x < 32.0 or size.y < 18.0:
		return

	var outline_width := clampf(size.y * 0.045, 0.65, 3.0)
	var body_left := size.x * 0.095
	var body_right := size.x * 0.905
	var body_top := size.y * 0.04
	var body_bottom := size.y * 0.78
	var tail_top := size.y * 0.20
	var tail_bottom := size.y * 0.96
	var notch_x := size.x * 0.035
	var fold_width := size.x * 0.055
	var shadow_offset := Vector2(0.0, maxf(1.0, size.y * 0.055))

	var left_tail := PackedVector2Array([
		Vector2(body_left + fold_width, tail_top),
		Vector2(0.0, tail_top),
		Vector2(notch_x, (tail_top + tail_bottom) * 0.5),
		Vector2(0.0, tail_bottom),
		Vector2(body_left + fold_width, tail_bottom),
	])
	var right_tail := PackedVector2Array([
		Vector2(body_right - fold_width, tail_top),
		Vector2(size.x, tail_top),
		Vector2(size.x - notch_x, (tail_top + tail_bottom) * 0.5),
		Vector2(size.x, tail_bottom),
		Vector2(body_right - fold_width, tail_bottom),
	])

	_draw_polygon_with_outline(_offset_points(left_tail, shadow_offset), Color(PALETTE.PEACH_INK, 0.16), Color.TRANSPARENT, 0.0)
	_draw_polygon_with_outline(_offset_points(right_tail, shadow_offset), Color(PALETTE.PEACH_INK, 0.16), Color.TRANSPARENT, 0.0)
	_draw_polygon_with_outline(left_tail, left_color.darkened(0.06), PALETTE.PEACH_INK, outline_width)
	_draw_polygon_with_outline(right_tail, right_color.darkened(0.06), PALETTE.PEACH_INK, outline_width)

	var left_fold := PackedVector2Array([
		Vector2(body_left, body_bottom - outline_width),
		Vector2(body_left + fold_width, tail_bottom - outline_width),
		Vector2(body_left + fold_width, body_bottom - outline_width),
	])
	var right_fold := PackedVector2Array([
		Vector2(body_right, body_bottom - outline_width),
		Vector2(body_right - fold_width, tail_bottom - outline_width),
		Vector2(body_right - fold_width, body_bottom - outline_width),
	])
	_draw_polygon_with_outline(left_fold, left_color.darkened(0.18), PALETTE.PEACH_INK, outline_width)
	_draw_polygon_with_outline(right_fold, right_color.darkened(0.18), PALETTE.PEACH_INK, outline_width)

	var body_rect := Rect2(
		Vector2(body_left, body_top),
		Vector2(body_right - body_left, body_bottom - body_top)
	)
	_draw_body(body_rect, outline_width)
	_draw_highlight(body_rect)
	if label_text == "MEAL" and not detail_text.is_empty():
		_draw_detail_divider(body_rect)
	if draw_copy:
		_draw_copy(body_rect)


func _draw_body(rect: Rect2, outline_width: float) -> void:
	var radius := clampf(rect.size.y * 0.22, 2.0, 12.0)
	if not dual_affinity:
		draw_style_box(_body_style(left_color, radius, true, true, outline_width), rect)
		return

	var left_rect := Rect2(rect.position, Vector2(rect.size.x * 0.5 + outline_width * 0.5, rect.size.y))
	var right_rect := Rect2(
		Vector2(rect.position.x + rect.size.x * 0.5 - outline_width * 0.5, rect.position.y),
		Vector2(rect.size.x * 0.5 + outline_width * 0.5, rect.size.y)
	)
	draw_style_box(_body_style(left_color, radius, true, false, outline_width), left_rect)
	draw_style_box(_body_style(right_color, radius, false, true, outline_width), right_rect)


func _body_style(
	fill: Color,
	radius: float,
	round_left: bool,
	round_right: bool,
	outline_width: float
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = PALETTE.PEACH_INK
	var border_width := int(round(outline_width))
	style.border_width_top = border_width
	style.border_width_bottom = border_width
	style.border_width_left = border_width if round_left else 0
	style.border_width_right = border_width if round_right else 0
	style.corner_radius_top_left = int(round(radius)) if round_left else 0
	style.corner_radius_bottom_left = int(round(radius)) if round_left else 0
	style.corner_radius_top_right = int(round(radius)) if round_right else 0
	style.corner_radius_bottom_right = int(round(radius)) if round_right else 0
	style.anti_aliasing = true
	return style


func _draw_highlight(rect: Rect2) -> void:
	var inset := maxf(1.5, rect.size.y * 0.12)
	draw_line(
		Vector2(rect.position.x + inset, rect.position.y + inset),
		Vector2(rect.end.x - inset, rect.position.y + inset),
		Color(PALETTE.PEACH_PAPER, 0.42),
		maxf(0.65, rect.size.y * 0.025),
		true
	)


func _draw_detail_divider(rect: Rect2) -> void:
	var divider_y := rect.position.y + rect.size.y * 0.54
	var divider_inset := rect.size.x * 0.18
	draw_line(
		Vector2(rect.position.x + divider_inset, divider_y),
		Vector2(rect.end.x - divider_inset, divider_y),
		PALETTE.PEACH_INK,
		maxf(0.65, rect.size.y * 0.025),
		true
	)


func _draw_copy(rect: Rect2) -> void:
	var title_size := clampi(int(round(rect.size.y * (0.29 if detail_text != "" else 0.38))), 8, 20)
	var detail_size := clampi(int(round(rect.size.y * 0.22)), 7, 14)
	var title_y := rect.position.y + rect.size.y * (0.42 if detail_text != "" else 0.63)
	draw_string(
		LABEL_FONT,
		Vector2(rect.position.x, title_y),
		label_text,
		HORIZONTAL_ALIGNMENT_CENTER,
		rect.size.x,
		title_size,
		PALETTE.PEACH_INK
	)
	if detail_text == "":
		return
	var detail_y := rect.position.y + rect.size.y * 0.82
	draw_string(
		LABEL_FONT,
		Vector2(rect.position.x, detail_y),
		detail_text,
		HORIZONTAL_ALIGNMENT_CENTER,
		rect.size.x,
		detail_size,
		PALETTE.PEACH_INK
	)


func _draw_polygon_with_outline(points: PackedVector2Array, fill: Color, outline: Color, width: float) -> void:
	draw_colored_polygon(points, fill)
	if width <= 0.0 or outline.a <= 0.0:
		return
	var closed := PackedVector2Array(points)
	closed.append(points[0])
	draw_polyline(closed, outline, width, true)


func _offset_points(points: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points:
		result.append(point + offset)
	return result
