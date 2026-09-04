extends Control
class_name TurnChangeGraphic

const PALETTE := preload("res://scripts/ui/GamePalette.gd")

var accent_color := PALETTE.SELECTION_BLUE


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
	# Give the ownership headline its own high-contrast printed plate.
	var headline_top := size.y * 0.04
	# Share an edge with the turn-number plate so the two shapes read as one unit.
	var headline_bottom := size.y * 0.64
	var headline_cut := 14.0
	var headline_shadow := PackedVector2Array([
		Vector2(headline_cut + 6.0, headline_top + 5.0),
		Vector2(size.x - 8.0, headline_top + 5.0),
		Vector2(size.x - headline_cut - 8.0, headline_bottom + 5.0),
		Vector2(6.0, headline_bottom + 5.0),
	])
	draw_colored_polygon(headline_shadow, Color(PALETTE.CARBON, 0.32))
	var headline_plate := PackedVector2Array([
		Vector2(headline_cut, headline_top),
		Vector2(size.x - 2.0, headline_top),
		Vector2(size.x - headline_cut - 2.0, headline_bottom),
		Vector2(0.0, headline_bottom),
	])
	draw_colored_polygon(headline_plate, PALETTE.SURFACE_PAPER)
	var headline_edge := PackedVector2Array(headline_plate)
	headline_edge.append(headline_plate[0])
	draw_polyline(headline_edge, PALETTE.CARBON, 2.0, true)
	draw_line(
		Vector2(headline_cut + 2.0, headline_top + 2.0),
		Vector2(size.x * 0.42, headline_top + 2.0),
		accent_color,
		3.0,
		true
	)

	# The hard offset keeps the turn-number plate grounded without a soft glow.
	var bar_top := size.y * 0.64
	var bar_bottom := size.y * 0.93
	var cut := 10.0
	var shadow := PackedVector2Array([
		Vector2(12.0, bar_top + 5.0),
		Vector2(size.x - 8.0, bar_top + 5.0),
		Vector2(size.x - 16.0, bar_bottom + 5.0),
		Vector2(4.0, bar_bottom + 5.0),
	])
	draw_colored_polygon(shadow, Color(PALETTE.CARBON, 0.32))
	var bar := PackedVector2Array([
		Vector2(cut, bar_top),
		Vector2(size.x - cut, bar_top),
		Vector2(size.x - 2.0 * cut, bar_bottom),
		Vector2(0.0, bar_bottom),
	])
	draw_colored_polygon(bar, PALETTE.SURFACE_PAPER_MUTED)
	var edge := PackedVector2Array(bar)
	edge.append(bar[0])
	draw_polyline(edge, PALETTE.CARBON, 2.0, true)
	# One local signal mark carries ownership without turning the whole banner neon.
	draw_line(Vector2(cut + 2.0, bar_top + 2.0), Vector2(size.x * 0.42, bar_top + 2.0), accent_color, 3.0, true)
