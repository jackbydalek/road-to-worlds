extends Control
class_name TitleBackgroundPattern

## A quiet, code-drawn title backdrop. The repeated clipped cards echo the
## game's angular card frame without turning the menu into a literal tabletop.

const PALETTE := preload("res://scripts/ui/GamePalette.gd")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), PALETTE.SURFACE_PAPER)
	_draw_accent_sashes()
	_draw_card_pattern()


func _draw_accent_sashes() -> void:
	var sash_width := maxf(150.0, size.x * 0.12)
	var red_sash := PackedVector2Array([
		Vector2(size.x * 0.64, -40.0),
		Vector2(size.x * 0.64 + sash_width, -40.0),
		Vector2(size.x * 0.35, size.y + 40.0),
		Vector2(size.x * 0.35 - sash_width, size.y + 40.0),
	])
	draw_colored_polygon(red_sash, Color(PALETTE.SIGNAL_RED, 0.035))

	var blue_sash := PackedVector2Array([
		Vector2(size.x * 0.91, -40.0),
		Vector2(size.x + 90.0, -40.0),
		Vector2(size.x * 0.69, size.y + 40.0),
		Vector2(size.x * 0.58, size.y + 40.0),
	])
	draw_colored_polygon(blue_sash, Color(PALETTE.SELECTION_BLUE, 0.04))


func _draw_card_pattern() -> void:
	const STEP := Vector2(184.0, 208.0)
	const CARD_SIZE := Vector2(76.0, 108.0)
	var row_count := ceili(size.y / STEP.y) + 2
	var column_count := ceili(size.x / STEP.x) + 2
	for row_index in range(-1, row_count):
		var row_shift := STEP.x * 0.5 if row_index % 2 != 0 else 0.0
		for column_index in range(-1, column_count):
			var origin := Vector2(
				float(column_index) * STEP.x + row_shift,
				float(row_index) * STEP.y
			)
			_draw_card_mark(origin, CARD_SIZE, row_index + column_index)


func _draw_card_mark(origin: Vector2, card_size: Vector2, pattern_index: int) -> void:
	var cut := 10.0
	var points := PackedVector2Array([
		origin + Vector2(cut, 0.0),
		origin + Vector2(card_size.x - cut, 0.0),
		origin + Vector2(card_size.x, cut),
		origin + Vector2(card_size.x, card_size.y - cut),
		origin + Vector2(card_size.x - cut, card_size.y),
		origin + Vector2(cut, card_size.y),
		origin + Vector2(0.0, card_size.y - cut),
		origin + Vector2(0.0, cut),
	])
	var fill := Color(PALETTE.SURFACE_PAPER_MUTED, 0.24 if pattern_index % 3 == 0 else 0.16)
	draw_colored_polygon(points, fill)
	var closed_points := points.duplicate()
	closed_points.append(points[0])
	draw_polyline(closed_points, Color(PALETTE.STRUCTURAL_EDGE, 0.16), 2.0, true)

	var center := origin + card_size * 0.5
	var accent := PALETTE.SIGNAL_RED if pattern_index % 4 == 0 else PALETTE.SELECTION_BLUE
	draw_line(
		center + Vector2(-15.0, 12.0),
		center + Vector2(15.0, -12.0),
		Color(accent, 0.13),
		4.0,
		true
	)
