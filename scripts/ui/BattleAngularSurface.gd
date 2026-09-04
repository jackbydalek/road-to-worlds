extends Control
class_name BattleAngularSurface

const PALETTE := preload("res://scripts/ui/GamePalette.gd")

var fill_color := PALETTE.CREAM
var accent_color := PALETTE.SKY
var dark_surface := false
var show_inner_keyline := true


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
	var cut := clampf(size.y * 0.16, 7.0, 12.0)
	var points := PackedVector2Array([
		Vector2(cut, 1),
		Vector2(size.x - 1, 1),
		Vector2(size.x - 1, size.y - cut),
		Vector2(size.x - cut, size.y - 1),
		Vector2(1, size.y - 1),
		Vector2(1, cut),
	])
	draw_colored_polygon(_offset_points(points, Vector2(3, 4)), Color(PALETTE.CARBON, 0.30))
	draw_colored_polygon(points, fill_color)

	# A flat printed wedge preserves the angular rhythm without reading as glass
	# or a holographic reflection.
	var diagonal := PackedVector2Array([
		Vector2(size.x * 0.72, 2),
		Vector2(size.x - 2, 2),
		Vector2(size.x - 2, size.y - cut),
		Vector2(size.x - cut, size.y - 2),
		Vector2(size.x * 0.86, size.y - 2),
	])
	draw_colored_polygon(
		diagonal,
		Color(PALETTE.COOL_WHITE, 0.035) if dark_surface else Color(PALETTE.CARBON, 0.045)
	)

	var structural_edge := Color(PALETTE.COOL_WHITE, 0.82) if dark_surface else PALETTE.CARBON
	_draw_closed_line(points, structural_edge, 2.5)
	# Color is a local category mark, not a glowing perimeter.
	draw_line(Vector2(cut, 1.5), Vector2(minf(size.x * 0.36, size.x - 18.0), 1.5), accent_color, 4.0, true)
	draw_line(Vector2(1.5, cut), Vector2(1.5, minf(size.y * 0.36, size.y - 14.0)), accent_color, 4.0, true)
	if show_inner_keyline:
		var inner := _scaled_points(points, Vector2(0.975, 0.88))
		_draw_closed_line(
			inner,
			Color(PALETTE.COOL_WHITE, 0.34) if dark_surface else Color(PALETTE.CARBON, 0.28),
			1.0
		)


func _draw_closed_line(points: PackedVector2Array, color: Color, width: float) -> void:
	var closed := PackedVector2Array(points)
	closed.append(points[0])
	draw_polyline(closed, color, width, true)


func _offset_points(points: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points:
		result.append(point + offset)
	return result


func _scaled_points(points: PackedVector2Array, scale: Vector2) -> PackedVector2Array:
	var center := size * 0.5
	var result := PackedVector2Array()
	for point in points:
		result.append((point - center) * scale + center)
	return result
